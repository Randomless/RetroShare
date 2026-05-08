# RetroShare Developer Guide

## Build System

- **Build tool**: qmake (Qt's build system)
- **Language**: C++14 minimum
- **Qt versions**: Qt5 and Qt6 supported

### Initial Setup

```powershell
# Clone and initialize submodules (required first step)
git submodule update --init --remote --force libbitdht/ libretroshare/ openpgpsdk/
```

### Build Commands

**Windows (MSYS2/MinGW64)**:
```bash
qmake -r -spec win32-g++ "CONFIG+=release"
mingw32-make -j4
```

**Linux/macOS**:
```bash
qmake CONFIG+=debug
make
```

### Running Tests

```bash
make check   # Runs unittests
```

Test executables: `tests/unittests/unittests`, `tests/librssimulator/librssimulator`

## Project Structure

```
libretroshare/       # Core library (most code lives here)
retroshare-gui/      # Qt desktop GUI
retroshare-service/  # Headless service binary
retroshare-friendserver/
plugins/             # GUI plugins (VOIP, etc.)
libbitdht/           # DHT networking library
jsonapi-generator/   # JSON API code generator
retroshare-webui/    # Web UI (submodule)
openpgpsdk/          # PGP implementation (submodule)
tests/unittests/     # Unit tests
tests/librssimulator/# Network simulator for testing
```

## Important CONFIG Options

Pass these to qmake to control the build:

| Option | Description |
|--------|-------------|
| `CONFIG+=no_retroshare_gui` | Skip GUI build |
| `CONFIG+=no_retroshare_service` | Skip service binary |
| `CONFIG+=rs_webui` | Enable web UI (requires `rs_jsonapi`) |
| `CONFIG+=rs_jsonapi` | Enable JSON REST API |
| `CONFIG+=retroshare_plugins` | Enable plugins |
| `CONFIG+=rs_autologin` | Enable auto-login (discouraged) |
| `CONFIG+=no_sqlcipher` | Use plain SQLite instead of SQLCipher |
| `CONFIG+=no_rs_sam3` | Disable I2P support |
| `CONFIG+=no_bitdht` | Disable DHT networking |
| `CONFIG+=rs_onlyhiddennode` | Only use hidden nodes |

## Platform Notes

- **Windows**: Use MSYS2 MinGW64. See `build_scripts/Windows-msys2/WindowsMSys2_InstallGuide.md`
- **Linux**: See `build_scripts/Debian+Ubuntu/Linux_InstallGuide.md`
- **macOS**: See `build_scripts/OSX/MacOS_X_InstallGuide.md`

## No Formal Linting

This project does not use clang-format, clang-tidy, or automated code formatters. Follow existing code style in each file.

## Key Dependencies (Windows/MSYS2)

```
mingw-w64-x86_64-qt5-base
mingw-w64-x86_64-sqlcipher
mingw-w64-x86_64-libxslt
mingw-w64-x86_64-xapian-core
mingw-w64-x86_64-miniupnpc
mingw-w64-x86_64-rapidjson
mingw-w64-x86_64-json-c
mingw-w64-x86_64-libbotan
mingw-w64-x86_64-asio
```

## Architecture Notes

- Main entrypoints: `libretroshare/src/libretroshare.pro`, `retroshare-gui/src/retroshare-gui.pro`
- Build configuration in `retroshare.pri` (shared across all subprojects)
- Database: SQLCipher by default (encrypted SQLite)
- Network: DHT + UPnP + I2P (optional)
- PGP: Uses RNP by default (can fallback to openpgp-sdk via `CONFIG+=rs_openpgpsdk`)