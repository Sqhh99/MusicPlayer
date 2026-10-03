//! The "dynamic island": a small always-on-top pill with the cover and a waveform.

use gpui::{
    Context, InteractiveElement, IntoElement, ParentElement, StatefulInteractiveElement, Styled, div, px,
};

use super::album_art::AlbumArt;
use super::root::MainView;
use crate::ui::theme::metrics;
use crate::ui::window_mode::WindowMode;

impl MainView {
    pub(super) fn render_island(&mut self, cx: &mut Context<Self>) -> impl IntoElement {
        let player = self.player.read(cx);
        let cover = player.track().and_then(|track| track.cover.clone());
        let playing = player.is_playing();
        let (width, height) = metrics::ISLAND_SIZE;

        div()
            .id("island")
            .w(px(width))
            .h(px(height))
            .flex()
            .items_center()
            .justify_between()
            .pr(px(12.0))
            .cursor_pointer()
            .on_click(cx.listener(|this, _, window, cx| this.switch_mode(WindowMode::Mini, window, cx)))
            .child(div().size(px(44.0)).flex().items_center().justify_center().child(AlbumArt::new(
                "island-art",
                cover,
                metrics::ISLAND_COVER_SIZE,
                metrics::ISLAND_COVER_SIZE / 2.0,
                playing,
            )))
            .child(self.island_wave.clone())
    }
}
