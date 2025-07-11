const rl = @import("raylib");
const constants = @import("constants.zig");

pub fn getClickedCell(mouse_pos: rl.Vector2) ?struct { row: usize, col: usize } {
    const x = @as(i32, @intFromFloat(mouse_pos.x));
    const y = @as(i32, @intFromFloat(mouse_pos.y));

    if (x < constants.GRID_X or x >= constants.GRID_X + constants.GRID_SIZE or
        y < constants.GRID_Y or y >= constants.GRID_Y + constants.GRID_SIZE)
    {
        return null;
    }

    const col = @as(usize, @intCast(@divFloor(x - constants.GRID_X, constants.CELL_SIZE)));
    const row = @as(usize, @intCast(@divFloor(y - constants.GRID_Y, constants.CELL_SIZE)));

    return .{ .row = row, .col = col };
}
