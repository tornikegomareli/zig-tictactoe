const std = @import("std");
const game = @import("game.zig");
const net = std.net;

pub const NetworkRole = enum {
    server,
    client,
    none,
};

pub const Message = union(enum) {
    connect: void,
    move: struct { row: u8, col: u8 },
    reset: void,
    disconnect: void,
    game_state: game.GameState,

    pub fn serialize(self: Message, writer: anytype) !void {
        try writer.writeByte(@intFromEnum(self));
        switch (self) {
            .connect, .reset, .disconnect => {},
            .move => |m| {
                try writer.writeByte(m.row);
                try writer.writeByte(m.col);
            },
            .game_state => |state| {
                for (state.board) |row| {
                    for (row) |cell| {
                        try writer.writeByte(@intFromEnum(cell));
                    }
                }
                try writer.writeByte(state.current_player);
                try writer.writeByte(state.moves_count);
                try writer.writeByte(if (state.game_over) 1 else 0);
                try writer.writeByte(if (state.winner) |w| @intFromEnum(w) else 255);
            },
        }
    }

    pub fn deserialize(reader: anytype) !Message {
        const msg_type = try reader.readByte();
        return switch (msg_type) {
            0 => .{ .connect = {} },
            1 => .{
                .move = .{
                    .row = try reader.readByte(),
                    .col = try reader.readByte(),
                },
            },
            2 => .{ .reset = {} },
            3 => .{ .disconnect = {} },
            4 => blk: {
                var state = game.GameState.init();
                for (&state.board) |*row| {
                    for (row) |*cell| {
                        cell.* = @enumFromInt(try reader.readByte());
                    }
                }
                state.current_player = try reader.readByte();
                state.moves_count = try reader.readByte();
                state.game_over = (try reader.readByte()) == 1;
                const winner_byte = try reader.readByte();
                state.winner = if (winner_byte == 255) null else @enumFromInt(winner_byte);
                break :blk .{ .game_state = state };
            },
            else => return error.InvalidMessage,
        };
    }
};

pub const NetworkGame = struct {
    role: NetworkRole,
    stream: ?net.Stream,
    server: ?net.Server,
    server_socket: ?std.posix.socket_t,
    local_player: u8,
    remote_player: u8,
    is_my_turn: bool,
    connection_status: [:0]const u8,
    recv_buffer: [1024]u8,
    recv_len: usize,

    pub fn init() NetworkGame {
        return .{
            .role = .none,
            .stream = null,
            .server = null,
            .server_socket = null,
            .local_player = 0,
            .remote_player = 0,
            .is_my_turn = false,
            .connection_status = "Not connected",
            .recv_buffer = undefined,
            .recv_len = 0,
        };
    }

    pub fn deinit(self: *NetworkGame) void {
        if (self.stream) |stream| {
            stream.close();
        }
        if (self.server) |*server| {
            server.deinit();
        }
        if (self.server_socket) |socket| {
            std.posix.close(socket);
        }
        self.* = init();
    }

    pub fn startServer(self: *NetworkGame, port: u16) !void {
        const address = try net.Address.parseIp("0.0.0.0", port);

        // non-blocking socket
        const socket_type = std.posix.SOCK.STREAM | std.posix.SOCK.NONBLOCK;
        self.server_socket = try std.posix.socket(address.any.family, socket_type, std.posix.IPPROTO.TCP);
        errdefer std.posix.close(self.server_socket.?);

        // address reuse for different times
        const reuse: c_int = 1;
        try std.posix.setsockopt(self.server_socket.?, std.posix.SOL.SOCKET, std.posix.SO.REUSEADDR, &std.mem.toBytes(reuse));

        try std.posix.bind(self.server_socket.?, &address.any, address.getOsSockLen());
        try std.posix.listen(self.server_socket.?, 1);

        self.role = .server;
        self.local_player = 1; // Server is X
        self.remote_player = 2; // Client is O
        self.connection_status = "Waiting for player...";
    }

    pub fn acceptConnection(self: *NetworkGame) !void {
        if (self.server_socket) |socket| {
            var client_addr: net.Address = undefined;
            var client_addr_len: std.posix.socklen_t = @sizeOf(net.Address);

            const client_socket = std.posix.accept(socket, &client_addr.any, &client_addr_len, std.posix.SOCK.NONBLOCK) catch |err| switch (err) {
                error.WouldBlock => return,
                else => return err,
            };

            self.stream = net.Stream{ .handle = client_socket };
            self.is_my_turn = true; // Server goes first
            self.connection_status = "Connected!";

            const timeout = std.posix.timeval{ .sec = 0, .usec = 1000 }; // 1ms timeout
            try std.posix.setsockopt(client_socket, std.posix.SOL.SOCKET, std.posix.SO.RCVTIMEO, &std.mem.toBytes(timeout));

            try self.sendMessage(.connect);
        }
    }

    pub fn connectToServer(self: *NetworkGame, host: []const u8, port: u16) !void {
        const address = try net.Address.parseIp(host, port);
        self.stream = try net.tcpConnectToAddress(address);

        const timeout = std.posix.timeval{ .sec = 0, .usec = 1000 }; // 1ms timeout
        try std.posix.setsockopt(self.stream.?.handle, std.posix.SOL.SOCKET, std.posix.SO.RCVTIMEO, &std.mem.toBytes(timeout));

        self.role = .client;
        self.local_player = 2;
        self.remote_player = 1;
        self.is_my_turn = false;
        self.connection_status = "Connected!";
    }

    pub fn sendMessage(self: *NetworkGame, msg: Message) !void {
        if (self.stream) |stream| {
            var buf: [256]u8 = undefined;
            var fbs = std.io.fixedBufferStream(&buf);
            try msg.serialize(fbs.writer());

            const data = fbs.getWritten();
            var header: [4]u8 = undefined;
            std.mem.writeInt(u32, &header, @intCast(data.len), .big);

            try stream.writer().writeAll(&header);
            try stream.writer().writeAll(data);
        }
    }

    pub fn receiveMessage(self: *NetworkGame) !?Message {
        if (self.stream) |stream| {
            // read more data into buffer
            const bytes_read = stream.read(self.recv_buffer[self.recv_len..]) catch |err| switch (err) {
                error.WouldBlock => 0,
                error.ConnectionResetByPeer, error.BrokenPipe => {
                    self.connection_status = "Connection lost";
                    return error.ConnectionLost;
                },
                else => return err,
            };

            self.recv_len += bytes_read;

            // check if we have enough for header
            if (self.recv_len < 4) return null;

            const msg_len = std.mem.readInt(u32, self.recv_buffer[0..4], .big);
            if (msg_len > 256) return error.MessageTooLarge;

            // check if we have the full message
            if (self.recv_len < 4 + msg_len) return null;

            var fbs = std.io.fixedBufferStream(self.recv_buffer[4 .. 4 + msg_len]);
            const msg = try Message.deserialize(fbs.reader());

            // remove proccessed message
            const total_len = 4 + msg_len;
            std.mem.copyForwards(u8, &self.recv_buffer, self.recv_buffer[total_len..self.recv_len]);
            self.recv_len -= total_len;

            return msg;
        }
        return null;
    }

    pub fn isConnected(self: *NetworkGame) bool {
        return self.stream != null;
    }

    pub fn canMakeMove(self: *const NetworkGame, current_player: u8) bool {
        return self.is_my_turn and current_player == self.local_player;
    }

    pub fn handleMove(self: *NetworkGame, row: usize, col: usize) !void {
        try self.sendMessage(.{ .move = .{ .row = @intCast(row), .col = @intCast(col) } });
        self.is_my_turn = false;
    }

    pub fn handleRemoteMove(self: *NetworkGame) void {
        self.is_my_turn = true;
    }
};
