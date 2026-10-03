//! Keyboard shortcuts.

use gpui::{App, KeyBinding, actions};

/// Key context set on the main view; shortcuts only apply inside it.
pub const KEY_CONTEXT: &str = "MusicPlayer";

actions!(
    music_player,
    [TogglePlay, Previous, Next, VolumeUp, VolumeDown, ToggleMute, TogglePlaylist, ToggleEq]
);

pub fn bind_keys(cx: &mut App) {
    let context = Some(KEY_CONTEXT);
    cx.bind_keys([
        KeyBinding::new("space", TogglePlay, context),
        KeyBinding::new("left", Previous, context),
        KeyBinding::new("right", Next, context),
        KeyBinding::new("up", VolumeUp, context),
        KeyBinding::new("down", VolumeDown, context),
        KeyBinding::new("m", ToggleMute, context),
        KeyBinding::new("l", TogglePlaylist, context),
        KeyBinding::new("e", ToggleEq, context),
    ]);
}
