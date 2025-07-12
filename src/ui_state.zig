pub const UIState = enum {
    main_menu,
    host_lobby,
    join_lobby,
    connecting,
    in_game,
};

pub const MenuSelection = enum {
    local_play,
    host_game,
    join_game,
};

pub const UIContext = struct {
    state: UIState,
    menu_selection: MenuSelection,
    host_port: [:0]const u8,
    join_address: [:0]const u8,
    join_port: [:0]const u8,
    input_buffer: [64]u8,
    input_len: usize,
    active_input: ?enum { host_port, join_address, join_port },
    error_message: ?[:0]const u8,

    pub fn init() UIContext {
        return .{
            .state = .main_menu,
            .menu_selection = .local_play,
            .host_port = "5555",
            .join_address = "127.0.0.1",
            .join_port = "5555",
            .input_buffer = undefined,
            .input_len = 0,
            .active_input = null,
            .error_message = null,
        };
    }

    pub fn setError(self: *UIContext, msg: [:0]const u8) void {
        self.error_message = msg;
    }

    pub fn clearError(self: *UIContext) void {
        self.error_message = null;
    }
};