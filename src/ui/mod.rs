//! User interface: theme, widgets and views.

pub mod anim;
pub mod icons;
pub mod theme;
pub mod views;
pub mod widgets;
pub mod window_mode;

use gpui::{App, Global};
use player_core::i18n::{Key, Lang, tr};

/// The active UI language.
#[derive(Debug, Clone, Copy)]
pub struct Locale(pub Lang);

impl Global for Locale {}

/// Looks up a UI string in the active language.
pub fn t(cx: &App, key: Key) -> &'static str {
    tr(cx.global::<Locale>().0, key)
}
