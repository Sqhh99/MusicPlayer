# MusicPlayer

![icon](resources/icons/listen1.ico)

A modern, minimalist music player built with Qt 6 QML.

## Screenshots

![Full Mode](examples/full.png)

![Mini Mode](examples/mini.png)

## Features

- **Dual Mode**: Full player with lyrics display / Compact mini player
- **Edge Snapping**: Mini mode snaps to screen edges
- **System Tray**: Full control from tray menu with icons
- **LRC Lyrics**: Synchronized lyrics display
- **Album Art**: Automatic extraction from audio files
- **Frameless Window**: Custom window controls with pin support

## Recent Changes

### UI Fixes
- `IconButton.qml`: Removed flashing hover background
- `AlbumArt.qml`: Fixed image not rendering (removed problematic layer.effect)
- `WindowControls.qml`: Repositioned pin button
- `MiniPlayer.qml`: Adjusted margins for visual balance
- `PlaylistOverlay.qml`: Fixed close button cursor (z-index and MouseArea structure)
- `Main.qml`: Hide dragArea when playlist open to prevent cursor conflicts

### Features
- Edge snapping in mini mode (20px threshold)
- System tray menu with icons for all actions

### Bug Fixes
- `musicplayer.cpp`: Fixed auto-play song info not updating (emit musicStart on track change)

## Build

```bash
cmake -B build -DCMAKE_PREFIX_PATH=D:/Qt/6.x.x/msvc2022_64
cmake --build build --config Release
```

## Tech Stack

- Qt 6.10+ (QtQuick, QtMultimedia with FFmpeg)
- C++17
- QML
