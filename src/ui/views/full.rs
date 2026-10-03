//! The full-size layout: album art on the left, title, controls and lyrics on the right.

use gpui::{
    Context, FontWeight, InteractiveElement, IntoElement, ParentElement, StatefulInteractiveElement, Styled,
    Window, div, prelude::FluentBuilder, px, svg,
};
use player_core::i18n::Key;

use super::album_art::AlbumArt;
use super::controls::{mode_toggle, player_action, progress, transport, volume};
use super::root::MainView;
use crate::model::PlayerModel;
use crate::ui::icons::Icon;
use crate::ui::t;
use crate::ui::theme::{Theme, metrics};

impl MainView {
    pub(super) fn render_full(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.global::<Theme>().clone();
        let player = self.player.read(cx);
        let playing = player.is_playing();
        let (repeat_one, shuffle) = (player.repeat_one(), player.shuffle());
        let track = player.track().cloned();
        let lyrics = self.lyrics_anim.value();

        let title =
            track.as_ref().map_or_else(|| t(cx, Key::NoSongSelected).into(), |track| track.title.clone());
        let artist = track
            .as_ref()
            .and_then(|track| track.artist.clone())
            .unwrap_or_else(|| t(cx, Key::LocalMusic).into());

        let album_column = div()
            .flex_none()
            .w(px(metrics::ALBUM_COLUMN_WIDTH))
            .h_full()
            .flex()
            .flex_col()
            .items_center()
            .justify_center()
            .gap(px(22.0))
            .child(AlbumArt::new(
                "full-art",
                track.as_ref().and_then(|track| track.cover.clone()),
                metrics::ALBUM_SIZE,
                metrics::ALBUM_RADIUS,
                playing,
            ))
            .child(div().w(px(metrics::ALBUM_SIZE)).child(self.eq_bars.clone()));

        let header = div()
            .flex()
            .flex_col()
            .gap(px(6.0))
            .pt(px(58.0))
            .pr(px(metrics::HEADER_INSET))
            .child(
                div()
                    .truncate()
                    .text_size(px(metrics::TITLE_SIZE))
                    .font_weight(FontWeight::SEMIBOLD)
                    .text_color(theme.text_primary)
                    .child(title),
            )
            .child(
                div()
                    .truncate()
                    .text_size(px(metrics::ARTIST_SIZE))
                    .text_color(theme.text_subtle)
                    .child(artist),
            );

        let panel_toggles = div()
            .flex()
            .items_center()
            .justify_between()
            .child(
                div()
                    .flex()
                    .gap(px(10.0))
                    .child(
                        mode_toggle("lyrics-toggle", Icon::MicVocal, self.show_lyrics, 34.0, 16.0, cx)
                            .on_click(cx.listener(|this, _, window, cx| this.toggle_lyrics(window, cx))),
                    )
                    .child(
                        mode_toggle("eq-toggle", Icon::SlidersVertical, self.show_eq, 34.0, 16.0, cx)
                            .on_click(cx.listener(|this, _, _, cx| this.toggle_eq(cx))),
                    ),
            )
            .child(
                div()
                    .flex()
                    .gap(px(10.0))
                    .child(
                        mode_toggle("shuffle", Icon::Shuffle, shuffle, 34.0, 16.0, cx)
                            .on_click(player_action(&self.player, PlayerModel::toggle_shuffle)),
                    )
                    .child(
                        mode_toggle(
                            "repeat",
                            if repeat_one { Icon::Repeat1 } else { Icon::Repeat },
                            repeat_one,
                            34.0,
                            16.0,
                            cx,
                        )
                        .on_click(player_action(&self.player, PlayerModel::toggle_repeat_one)),
                    ),
            );

        let controls = div()
            .absolute()
            .size_full()
            .flex()
            .flex_col()
            .justify_center()
            .gap(px(10.0))
            .opacity(1.0 - lyrics)
            .child(panel_toggles)
            .child(progress("full-progress", &self.player, metrics::PROGRESS_HEIGHT, 11.0, cx))
            .child(div().flex().justify_center().pt(px(8.0)).child(transport(
                "full-transport",
                &self.player,
                metrics::CONTROL_SIZE_MD,
                24.0,
                36.0,
                cx,
            )));

        let center = div()
            .relative()
            .flex_1()
            .min_h(px(200.0))
            .when(lyrics < 1.0, |el| el.child(controls))
            .when(lyrics > 0.0, |el| {
                el.child(div().absolute().size_full().opacity(lyrics).child(self.lyrics.clone()))
            });

        let playlist_open = self.playlist_open;
        let playlist_button = div()
            .id("playlist-button")
            .h(px(36.0))
            .px(px(10.0))
            .flex()
            .items_center()
            .gap(px(8.0))
            .rounded(px(12.0))
            .border_1()
            .border_color(theme.button_border)
            .cursor_pointer()
            .map(|el| {
                if playlist_open {
                    el.bg(theme.button_active_bg)
                } else {
                    el.bg(theme.button_bg)
                        .hover(|s| s.bg(theme.button_hover_bg))
                        .active(|s| s.bg(theme.button_pressed_bg))
                }
            })
            .on_click(cx.listener(move |this, _, _, cx| this.set_playlist_open(!playlist_open, cx)))
            .child(svg().path(Icon::ListMusic.path()).size(px(16.0)).text_color(theme.icon.opacity(0.78)))
            .child(
                div()
                    .text_size(px(12.0))
                    .font_weight(FontWeight::SEMIBOLD)
                    .text_color(theme.text_secondary)
                    .child(t(cx, Key::Playlist)),
            );

        let bottom_bar = div()
            .flex_none()
            .h(px(metrics::BOTTOM_BAR_HEIGHT))
            .flex()
            .items_center()
            .justify_between()
            .child(playlist_button)
            .child(volume(&self.player, cx));

        let details_column =
            div().flex_1().min_w_0().h_full().flex().flex_col().child(header).child(center).child(bottom_bar);

        div()
            .size_full()
            .p(px(metrics::OUTER_PADDING))
            .flex()
            .gap(px(metrics::COLUMN_SPACING))
            .child(album_column)
            .child(details_column)
    }
}
