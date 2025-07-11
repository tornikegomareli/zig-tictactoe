const rl = @import("raylib");
const std = @import("std");
const game = @import("game.zig");
const renderer = @import("renderer.zig");
const input = @import("input.zig");
const constants = @import("constants.zig");

pub fn main() !void {
    var gameState = game.GameState.init();

    rl.initWindow(constants.SCREEN_WIDTH, constants.SCREEN_HEIGHT, "Tic Tac Toe");
    defer rl.closeWindow();

    rl.setTargetFPS(60);

    while (!rl.windowShouldClose()) {
        rl.beginDrawing();
        defer rl.endDrawing();

        rl.clearBackground(.white);

        const mouse_position = rl.getMousePosition();

        renderer.drawGrid();
        renderer.drawBoard(&gameState);

        if (gameState.game_over) {
            if (renderer.drawGameOver(&gameState, mouse_position)) |should_reset| {
                if (should_reset) {
                    gameState = game.GameState.init();
                }
            }
        }

        if (!gameState.game_over and rl.isMouseButtonPressed(.left)) {
            if (input.getClickedCell(mouse_position)) |cell| {
                gameState.makeMove(cell.row, cell.col);
            }
        }
    }
}
