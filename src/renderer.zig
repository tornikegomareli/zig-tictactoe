const rl = @import("raylib");
const game = @import("game.zig");
const constants = @import("constants.zig");

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