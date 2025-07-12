const rl = @import("raylib");
const std = @import("std");
const game = @import("game.zig");
const renderer = @import("renderer.zig");
const input = @import("input.zig");
const constants = @import("constants.zig");
const network = @import("network.zig");
const ui_state = @import("ui_state.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var gameState = game.GameState.init();
    var netGame = network.NetworkGame.init();
    defer netGame.deinit();
    
    var ui = ui_state.UIContext.init();
    var is_local_play = false;

    rl.setConfigFlags(rl.ConfigFlags{ .window_highdpi = true, .window_resizable = false });
    rl.initWindow(constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT, "Tic Tac Toe - Multiplayer");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        const mouse_position = rl.getMousePosition();

        switch (ui.state) {
            .main_menu => {
                const hovered = renderer.drawMainMenu(&ui, mouse_position);

                if (rl.isMouseButtonPressed(.left)) {
                    if (hovered) |selection| {
                        switch (selection) {
                            .local_play => {
                                ui.state = .in_game;
                                is_local_play = true;
                                gameState = game.GameState.init();
                            },
                            .host_game => {
                                ui.state = .host_lobby;
                                ui.clearError();
                            },
                            .join_game => {
                                ui.state = .join_lobby;
                                ui.clearError();
                            },
                        }
                    }
                }
            },
            .host_lobby => {
                renderer.drawHostLobby(&ui, &netGame);

                if (!netGame.isConnected()) {
                    if (netGame.server_socket == null) {
                        const port = std.fmt.parseInt(u16, ui.host_port, 10) catch 5555;
                        netGame.startServer(port) catch |err| {
                            ui.setError("Failed to start server");
                            std.log.err("Failed to start server: {}", .{err});
                            ui.state = .main_menu;
                            continue;
                        };
                    }
                    
                    netGame.acceptConnection() catch |err| {
                        std.log.err("Accept error: {}", .{err});
                    };
                } else {
                    ui.state = .in_game;
                    gameState = game.GameState.init();
                    is_local_play = false;
                }

                if (rl.isMouseButtonPressed(.left)) {
                    if (mouse_position.x >= 50 and mouse_position.x < 150 and
                        mouse_position.y >= 400 and mouse_position.y < 440) {
                        netGame.deinit();
                        ui.state = .main_menu;
                    }
                }
            },
            .join_lobby => {
                const buttons = renderer.drawJoinLobby(&ui, mouse_position);

                if (rl.isMouseButtonPressed(.left)) {
                    if (buttons.connect) {
                        ui.state = .connecting;
                    } else if (buttons.back) {
                        ui.state = .main_menu;
                    }
                }
            },
            .connecting => {
                renderer.drawConnecting();

                const port = std.fmt.parseInt(u16, ui.join_port, 10) catch 5555;
                netGame.connectToServer(ui.join_address, port) catch |err| {
                    ui.setError("Failed to connect");
                    std.log.err("Failed to connect: {}", .{err});
                    ui.state = .join_lobby;
                    continue;
                };

                ui.state = .in_game;
                gameState = game.GameState.init();
                is_local_play = false;
            },
            .in_game => {
                renderer.drawGrid();
                renderer.drawBoard(&gameState);

                if (!is_local_play and netGame.isConnected()) {
                    renderer.drawNetworkStatus(&netGame, gameState.current_player);
                }

                if (gameState.game_over) {
                    if (renderer.drawGameOver(&gameState, mouse_position)) |should_reset| {
                        if (should_reset) {
                            gameState = game.GameState.init();
                            if (!is_local_play) {
                                try netGame.sendMessage(.reset);
                            }
                        }
                    }
                }

                if (!is_local_play and netGame.isConnected()) {
                    if (try netGame.receiveMessage()) |msg| {
                        switch (msg) {
                            .move => |move| {
                                gameState.makeMove(move.row, move.col);
                                netGame.handleRemoteMove();
                            },
                            .reset => {
                                gameState = game.GameState.init();
                            },
                            .disconnect => {
                                netGame.deinit();
                                ui.state = .main_menu;
                                ui.setError("Opponent disconnected");
                            },
                            .connect => {},
                            .game_state => |state| {
                                gameState = state;
                            },
                        }
                    }
                }

                if (!gameState.game_over and rl.isMouseButtonPressed(.left)) {
                    if (input.getClickedCell(mouse_position)) |cell| {
                        if (is_local_play) {
                            gameState.makeMove(cell.row, cell.col);
                        } else if (netGame.canMakeMove(gameState.current_player)) {
                            const old_state = gameState;
                            gameState.makeMove(cell.row, cell.col);
                            
                            if (gameState.moves_count > old_state.moves_count) {
                                try netGame.handleMove(cell.row, cell.col);
                            }
                        }
                    }
                }

                if (rl.isKeyPressed(.escape)) {
                    if (!is_local_play) {
                        try netGame.sendMessage(.disconnect);
                        netGame.deinit();
                    }
                    ui.state = .main_menu;
                    gameState = game.GameState.init();
                }
            },
        }
    }
}

test "network message serialization" {
    const move_msg = network.Message{ .move = .{ .row = 1, .col = 2 } };
    
    var buf: [256]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    
    try move_msg.serialize(fbs.writer());
    
    fbs.pos = 0;
    const deserialized = try network.Message.deserialize(fbs.reader());
    
    try std.testing.expectEqual(move_msg.move.row, deserialized.move.row);
    try std.testing.expectEqual(move_msg.move.col, deserialized.move.col);
}