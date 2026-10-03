<p align="center">
  <img src="resources/appIcon.png" width="128" height="128" />
</p>

<h1 align="center">MusicPlayer</h1>

<p align="center">
  A modern, minimalist local music player built with Rust and <a href="https://www.gpui.rs">GPUI</a>.
</p>

---

## Screenshots

<p align="center">
  <img src="examples/full.png" width="45%" />
  <img src="examples/mini.png" width="45%" />
</p>

## Features

- **Three window modes**: the full player, a compact mini player, and a "dynamic island" pill
  pinned to the top of the screen, with animated transitions between them
- **Synchronized lyrics** from `.lrc` files next to the track, with automatic encoding detection
  (UTF-8, UTF-16, GB18030, Shift-JIS)
- **Album art and tags**: embedded cover, title and artist, or a `song.jpg` / `song.png` next to the track
- **3-band equalizer** (bass / mid / treble) that is applied live to the audio
- **Shuffle with history** (previous/next walk back and forth through what was played) and repeat-one
- **System tray** with playback controls; closing the window keeps the music playing
- **Frameless translucent window** with day/night themes, adjustable material strength, pin-on-top
  and edge snapping in mini mode
- **Chinese and English** interface
- Single instance: launching again brings the running player to the front

Supported formats: MP3, FLAC, WAV, AAC/M4A (AAC and ALAC), Ogg Vorbis.

### Keyboard shortcuts

| Key | Action |
| --- | --- |
| `Space` | Play / pause |
| `←` / `→` | Previous / next track |
| `↑` / `↓` | Volume ±5 |
| `M` | Mute |
| `L` | Playlist |
| `E` | Equalizer |

## Build

Requires a recent stable Rust toolchain (edition 2024).

```bash
cargo run --release
```

Platform prerequisites:

- **Windows**: Visual Studio Build Tools (MSVC) and the Windows SDK. Release builds compile
  shaders with the SDK's `fxc.exe`; if it is not found automatically, set `GPUI_FXC_PATH`
  to its full path.
- **Linux**: `libasound2-dev libxkbcommon-dev libxkbcommon-x11-dev libwayland-dev libx11-xcb-dev
  libfontconfig-dev libfreetype6-dev libvulkan-dev libdbus-1-dev pkg-config`
- **macOS**: Xcode command line tools.

Pinning, island positioning and edge snapping use Win32 APIs; on other platforms those
features are unavailable and closing the window minimizes it instead of hiding it to the tray.

`examples/MusicPlayer-Setup.iss` builds a Windows installer from `target/release/MusicPlayer.exe`
with [Inno Setup](https://jrsoftware.org/isinfo.php).

## Project layout

```
crates/player-core/   Platform-independent logic, fully unit tested:
                      play queue (shuffle/repeat), LRC parsing, EQ filters,
                      settings, strings (zh/en), geometry and easing
src/
  audio/              Audio thread (rodio) and the equalizer source
  media/              Tag, cover art and duration reading (lofty)
  model/              PlayerModel and SettingsModel, shared by all views
  platform/           Win32 window helpers, system tray, single instance
  ui/                 Theme, widgets and views (full / mini / island, overlays)
  app.rs              Wiring: window, tray, persistence
resources/            App icon and Lucide SVG icons
```

Settings are stored as JSON in the user config directory
(`%APPDATA%\sqhh99\MusicPlayer\config\settings.json` on Windows).

```bash
cargo test --workspace   # all tests
cargo test -p player-core   # core logic only, no GPUI build needed
```

## Tech stack

- **UI**: [GPUI](https://crates.io/crates/gpui)
- **Audio**: [rodio](https://crates.io/crates/rodio) + [symphonia](https://crates.io/crates/symphonia)
- **Metadata**: [lofty](https://crates.io/crates/lofty)
- **Icons**: [Lucide](https://lucide.dev)
