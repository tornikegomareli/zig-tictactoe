const rl = @import("raylib");
const game = @import("game.zig");
const constants = @import("constants.zig");
const ui_state = @import("ui_state.zig");
const network = @import("network.zig");

pub fn drawGrid() void {
    for (1..3) |i| {
        const ix: i32 = @intCast(i);
        const x = constants.GRID_X + ix * constants.CELL_SIZE;
        const y = constants.GRID_Y + ix * constants.CELL_SIZE;
        
        rl.drawLine(x, constants.GRID_Y, x, constants.GRID_Y + constants.GRID_SIZE, .black);
        rl.drawLine(constants.GRID_X, y, constants.GRID_X + constants.GRID_SIZE, y, .black);
    }
    
    rl.drawRectangleLines(constants.GRID_X, constants.GRID_Y, constants.GRID_SIZE, constants.GRID_SIZE, .black);
}

pub fn drawBoard(state: *const game.GameState) void {
    for (0..3) |row| {
        for (0..3) |col| {
            const centerX = constants.GRID_X + @as(i32, @intCast(col)) * constants.CELL_SIZE + constants.CELL_SIZE / 2;
            const centerY = constants.GRID_Y + @as(i32, @intCast(row)) * constants.CELL_SIZE + constants.CELL_SIZE / 2;
            const offset = constants.CELL_SIZE / 3;

            switch (state.board[row][col]) {
                .x => {
                    rl.drawLineEx(
                        rl.Vector2{ .x = @floatFromInt(centerX - offset), .y = @floatFromInt(centerY - offset) }, 
                        rl.Vector2{ .x = @floatFromInt(centerX + offset), .y = @floatFromInt(centerY + offset) }, 
                        3.0, 
                        rl.Color.red
                    );
                    rl.drawLineEx(
                        rl.Vector2{ .x = @floatFromInt(centerX + offset), .y = @floatFromInt(centerY - offset) }, 
                        rl.Vector2{ .x = @floatFromInt(centerX - offset), .y = @floatFromInt(centerY + offset) }, 
                        3.0, 
                        rl.Color.red
                    );
                },
                .o => {
                    rl.drawCircleLines(centerX, centerY, @divFloor(constants.CELL_SIZE, 3), .blue);
                },
                .empty => {},
            }
        }
    }
}

pub fn drawGameOver(state: *const game.GameState, mouse_pos: rl.Vector2) ?bool {
    rl.drawRectangle(0, 0, constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT, 
        rl.Color{ .r = 0, .g = 0, .b = 0, .a = 180 });

    const text = if (state.winner) |w|
        if (w == .x) "X Wins!" else "O Wins!"
    else
        "Draw!";

    const text_width = rl.measureText(text, 60);
    rl.drawText(text, @divFloor(constants.SCREEN_WIDTH - text_width, 2), 150, 60, rl.Color.white);

    const button_x = 300;
    const button_y = 250;
    const button_width = 200;
    const button_height = 60;

    rl.drawRectangle(button_x, button_y, button_width, button_height, rl.Color.gray);
    rl.drawRectangleLines(button_x, button_y, button_width, button_height, rl.Color.white);

    const button_text = "Play Again";
    const button_text_width = rl.measureText(button_text, 30);
    rl.drawText(button_text, button_x + @divFloor(button_width - button_text_width, 2), button_y + 15, 30, rl.Color.white);

    if (rl.isMouseButtonReleased(.left)) {
        if (mouse_pos.x >= button_x and
            mouse_pos.x < button_x + button_width and
            mouse_pos.y >= button_y and
            mouse_pos.y < button_y + button_height)
        {
            return true;
        }
    }
    
    return false;
}

pub fn drawMainMenu(ui: *const ui_state.UIContext, mouse_pos: rl.Vector2) ui_state.MenuSelection {
    const title = "Tic Tac Toe";
    const title_size = 60;
    const title_width = rl.measureText(title, title_size);
    rl.drawText(title, @divFloor(constants.SCREEN_WIDTH - title_width, 2), 80, title_size, rl.Color.black);

    const button_width = 300;
    const button_height = 60;
    const button_x = @divFloor(constants.SCREEN_WIDTH - button_width, 2);
    var button_y: i32 = 200;
    const button_spacing = 80;

    const buttons = [_]struct { text: [:0]const u8, selection: ui_state.MenuSelection }{
        .{ .text = "Local Play", .selection = .local_play },
        .{ .text = "Host Game", .selection = .host_game },
        .{ .text = "Join Game", .selection = .join_game },
    };

    var hovered_selection = ui.menu_selection;

    for (buttons) |button| {
        const is_hovered = mouse_pos.x >= @as(f32, @floatFromInt(button_x)) and
            mouse_pos.x < @as(f32, @floatFromInt(button_x + button_width)) and
            mouse_pos.y >= @as(f32, @floatFromInt(button_y)) and
            mouse_pos.y < @as(f32, @floatFromInt(button_y + button_height));

        const color = if (is_hovered) rl.Color.dark_gray else rl.Color.gray;
        rl.drawRectangle(button_x, button_y, button_width, button_height, color);
        rl.drawRectangleLines(button_x, button_y, button_width, button_height, rl.Color.black);

        const text_width = rl.measureText(button.text, 30);
        rl.drawText(button.text, button_x + @divFloor(button_width - text_width, 2), button_y + 15, 30, rl.Color.white);

        if (is_hovered) {
            hovered_selection = button.selection;
        }

        button_y += button_spacing;
    }

    return hovered_selection;
}

pub fn drawHostLobby(ui: *const ui_state.UIContext, net_game: *const network.NetworkGame) void {
    const title = "Host Game";
    const title_width = rl.measureText(title, 40);
    rl.drawText(title, @divFloor(constants.SCREEN_WIDTH - title_width, 2), 50, 40, rl.Color.black);

    const info_y = 150;
    const port_text = "Port: ";
    rl.drawText(port_text, 250, info_y, 25, rl.Color.black);
    rl.drawText(ui.host_port, 250 + rl.measureText(port_text, 25), info_y, 25, rl.Color.dark_gray);

    const status_y = 250;
    const status_width = rl.measureText(net_game.connection_status, 30);
    rl.drawText(net_game.connection_status, @divFloor(constants.SCREEN_WIDTH - status_width, 2), status_y, 30, rl.Color.dark_green);

    const back_button_x = 50;
    const back_button_y = 400;
    rl.drawRectangle(back_button_x, back_button_y, 100, 40, rl.Color.gray);
    rl.drawText("Back", back_button_x + 25, back_button_y + 10, 20, rl.Color.white);
}

pub fn drawJoinLobby(ui: *const ui_state.UIContext, mouse_pos: rl.Vector2) struct { connect: bool, back: bool } {
    const title = "Join Game";
    const title_width = rl.measureText(title, 40);
    rl.drawText(title, @divFloor(constants.SCREEN_WIDTH - title_width, 2), 50, 40, rl.Color.black);

    const field_x = 250;
    var field_y: i32 = 150;
    const field_width = 300;
    const field_height = 40;
    const field_spacing = 80;

    rl.drawText("Host:", field_x - 80, field_y + 8, 25, rl.Color.black);
    const addr_color = if (ui.active_input == .join_address) rl.Color.light_gray else rl.Color.white;
    rl.drawRectangle(field_x, field_y, field_width, field_height, addr_color);
    rl.drawRectangleLines(field_x, field_y, field_width, field_height, rl.Color.black);
    rl.drawText(ui.join_address, field_x + 10, field_y + 8, 25, rl.Color.black);

    field_y += field_spacing;

    rl.drawText("Port:", field_x - 80, field_y + 8, 25, rl.Color.black);
    const port_color = if (ui.active_input == .join_port) rl.Color.light_gray else rl.Color.white;
    rl.drawRectangle(field_x, field_y, field_width, field_height, port_color);
    rl.drawRectangleLines(field_x, field_y, field_width, field_height, rl.Color.black);
    rl.drawText(ui.join_port, field_x + 10, field_y + 8, 25, rl.Color.black);

    const button_y = 350;
    const connect_button_x = 300;
    const connect_button_width = 200;
    const connect_button_height = 50;

    const connect_hovered = mouse_pos.x >= @as(f32, @floatFromInt(connect_button_x)) and
        mouse_pos.x < @as(f32, @floatFromInt(connect_button_x + connect_button_width)) and
        mouse_pos.y >= @as(f32, @floatFromInt(button_y)) and
        mouse_pos.y < @as(f32, @floatFromInt(button_y + connect_button_height));

    const connect_color = if (connect_hovered) rl.Color.dark_green else rl.Color.green;
    rl.drawRectangle(connect_button_x, button_y, connect_button_width, connect_button_height, connect_color);
    rl.drawText("Connect", connect_button_x + 50, button_y + 12, 30, rl.Color.white);

    const back_button_x = 50;
    const back_button_y = 400;
    const back_hovered = mouse_pos.x >= @as(f32, @floatFromInt(back_button_x)) and
        mouse_pos.x < @as(f32, @floatFromInt(back_button_x + 100)) and
        mouse_pos.y >= @as(f32, @floatFromInt(back_button_y)) and
        mouse_pos.y < @as(f32, @floatFromInt(back_button_y + 40));

    const back_color = if (back_hovered) rl.Color.dark_gray else rl.Color.gray;
    rl.drawRectangle(back_button_x, back_button_y, 100, 40, back_color);
    rl.drawText("Back", back_button_x + 25, back_button_y + 10, 20, rl.Color.white);

    if (ui.error_message) |msg| {
        const error_width = rl.measureText(msg, 20);
        rl.drawText(msg, @divFloor(constants.SCREEN_WIDTH - error_width, 2), 300, 20, rl.Color.red);
    }

    return .{ .connect = connect_hovered, .back = back_hovered };
}

pub fn drawConnecting() void {
    const text = "Connecting...";
    const text_width = rl.measureText(text, 40);
    rl.drawText(text, @divFloor(constants.SCREEN_WIDTH - text_width, 2), @divFloor(constants.SCREEN_HEIGHT - 40, 2), 40, rl.Color.black);
}

pub fn drawNetworkStatus(net_game: *const network.NetworkGame, current_player: u8) void {
    const player_text = if (net_game.local_player == 1) "You are X" else "You are O";
    rl.drawText(player_text, 10, 40, 20, rl.Color.black);

    const turn_text = if (net_game.canMakeMove(current_player)) "Your turn" else "Opponent's turn";
    const turn_color = if (net_game.canMakeMove(current_player)) rl.Color.green else rl.Color.red;
    rl.drawText(turn_text, 10, 65, 20, turn_color);

    rl.drawText(net_game.connection_status, 10, 90, 15, rl.Color.dark_gray);
}