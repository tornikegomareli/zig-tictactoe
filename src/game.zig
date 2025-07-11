const std = @import("std");

pub const Cell = enum(u8) { empty = 0, x = 1, o = 2 };

pub const GameState = struct {
    board: [3][3]Cell,
    current_player: u8,
    moves_count: u8,
    game_over: bool,
    winner: ?Cell,

    pub fn init() GameState {
        return .{
            .board = .{.{ .empty, .empty, .empty }} ** 3,
            .current_player = 1,
            .moves_count = 0,
            .game_over = false,
            .winner = null,
        };
    }

    pub fn makeMove(self: *GameState, row: usize, col: usize) void {
        if (self.board[row][col] != .empty or self.game_over) return;

        self.board[row][col] = if (self.current_player == 1) .x else .o;
        self.moves_count += 1;

        if (self.checkWin(row, col)) |winner| {
            self.winner = winner;
            self.game_over = true;
        } else if (self.moves_count == 9) {
            self.game_over = true;
        } else {
            self.current_player = if (self.current_player == 1) 2 else 1;
        }
    }

    fn checkWin(self: *const GameState, last_row: usize, last_col: usize) ?Cell {
        if (self.moves_count < 5) return null;

        const player = self.board[last_row][last_col];
        if (player == .empty) return null;

        if (self.board[last_row][0] == player and
            self.board[last_row][1] == player and
            self.board[last_row][2] == player)
        {
            return player;
        }

        if (self.board[0][last_col] == player and
            self.board[1][last_col] == player and
            self.board[2][last_col] == player)
        {
            return player;
        }

        if (last_row == last_col) {
            if (self.board[0][0] == player and
                self.board[1][1] == player and
                self.board[2][2] == player)
            {
                return player;
            }
        }

        if (last_row + last_col == 2) {
            if (self.board[0][2] == player and
                self.board[1][1] == player and
                self.board[2][0] == player)
            {
                return player;
            }
        }

        return null;
    }
};
