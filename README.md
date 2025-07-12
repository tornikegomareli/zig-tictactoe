# Tic Tac Toe Multiplayer in Zig

A multiplayer Tic Tac Toe game built to learn the Zig programming language.

![CleanShot 2025-07-13 at 03 11 27](https://github.com/user-attachments/assets/7ff5ff5c-0f09-4dbe-b793-e4672a9ecee6)


## Educational Purpose

This project was created for educational purposes to learn:
- Zig programming language fundamentals
- TCP socket networking
- State management
- Modularity

## What we have

- **Local Play**: Two players on the same computer
- **Network Multiplayer**: Host or join games over TCP
- **Real-time Synchronization**: Instant move updates between players
- **Cross-platform**: Works on macOS, Linux, and Windows

## Technologies Used

- **[Zig](https://ziglang.org/)** - A general-purpose programming language and toolchain
- **[Raylib](https://www.raylib.com/)** - A simple and easy-to-use library for game development
- **[raylib-zig](https://github.com/Not-Nik/raylib-zig)** - Zig bindings for Raylib

## Prerequisites

- Zig 0.14.0 or later
- Git

## Getting Started

1. Clone the repository:
```bash
git clone https://github.com/yourusername/learn-zig.git
cd learn-zig
```

2. Build the project:
```bash
zig build
```

3. Run the game:
```bash
zig build run
```

## How to Play

### Local Play
1. Launch the game and select "Local Play"
2. Players take turns clicking on the grid
3. First player to get 3 in a row wins

### Network Multiplayer

**To host a game:**
1. Select "Host Game" from the main menu
2. Note the port number (default: 5555)
3. Share your IP address with the other player
4. Wait for them to connect

**To join a game:**
1. Select "Join Game" from the main menu
2. Enter the host's IP address
3. Enter the port number (default: 5555)
4. Click "Connect"

**Game Rules:**
- The host plays as X and goes first
- The client plays as O
- Players take turns clicking empty squares
- First to get 3 in a row wins

## Project Structure

```
src/
├── main.zig         # Entry point and game loop
├── game.zig         # Game logic and state management
├── renderer.zig     # All drawing and UI rendering
├── network.zig      # TCP networking implementation
├── ui_state.zig     # UI state definitions
├── input.zig        # Input handling utilities
└── constants.zig    # Shared constants and configuration
```

## Building from Source

The project uses Zig's built-in build system. The `build.zig` file configures:
- Executable compilation
- Raylib dependency linking
- Build options and flags

To build in release mode for better performance:
```bash
zig build -Doptimize=ReleaseFast
```

## Network Protocol

The multiplayer mode uses a simple TCP protocol with message types:
- `CONNECT` - Initial handshake
- `MOVE` - Transmit player moves
- `RESET` - Restart the game
- `DISCONNECT` - Clean disconnection

Messages are serialized with a 4-byte header indicating message length.

## Learning Resources

For those learning Zig:
- [Zig Language Documentation](https://ziglang.org/documentation/master/)
- [Ziglearn](https://ziglearn.org/)
- [Zig by Example](https://zigbyexample.github.io/)

For Raylib:
- [Raylib Cheatsheet](https://www.raylib.com/cheatsheet/cheatsheet.html)
- [Raylib Examples](https://www.raylib.com/examples.html)

## Acknowledgments

- The Zig community for excellent documentation
- [Raylib](https://github.com/raysan5/raylib)
- [raylib-zig](https://github.com/Not-Nik/raylib-zig) for the Zig bindings of the Raylib
