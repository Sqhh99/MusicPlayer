//! Playlist overlay: header with open/close buttons and the list of tracks.

use std::ops::Range;

use gpui::{
    App, Context, Div, Entity, EventEmitter, FontWeight, InteractiveElement, IntoElement, ParentElement,
    Render, ScrollStrategy, StatefulInteractiveElement, Styled, UniformListScrollHandle, Window,
    WindowControlArea, div, prelude::FluentBuilder, px, svg, uniform_list,
};
use player_core::i18n::Key;
use player_core::media_paths;
use player_core::time::{UNKNOWN_DURATION, fmt_duration};

use crate::model::PlayerModel;
use crate::ui::icons::Icon;
use crate::ui::t;
use crate::ui::theme::Theme;
use crate::ui::widgets::IconButton;

const HEADER_HEIGHT: f32 = 64.0;
const ROW_HEIGHT: f32 = 54.0;
const ROW_GAP: f32 = 6.0;

pub enum PlaylistEvent {
    Close,
    OpenFiles,
}

pub struct PlaylistView {
    player: Entity<PlayerModel>,
    scroll: UniformListScrollHandle,
}

impl EventEmitter<PlaylistEvent> for PlaylistView {}

impl PlaylistView {
    pub fn new(player: Entity<PlayerModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(&player, |_, _, cx| cx.notify()).detach();
        Self { player, scroll: UniformListScrollHandle::new() }
    }

    /// Brings the current track into view; called when the overlay opens.
    pub fn reveal_current(&self, cx: &App) {
        if let Some(index) = self.player.read(cx).current_index() {
            self.scroll.scroll_to_item(index, ScrollStrategy::Center);
        }
    }

    fn render_rows(&mut self, range: Range<usize>, cx: &mut Context<Self>) -> Vec<Div> {
        let theme = cx.global::<Theme>().clone();
        let local_music = t(cx, Key::LocalMusic);
        let player = self.player.read(cx);
        let current = player.current_index();
        range
            .filter_map(|index| {
                let path = player.tracks().get(index)?;
                let is_current = current == Some(index);
                let duration = player
                    .track_duration(index)
                    .map(|d| fmt_duration(d.as_millis() as u64))
                    .unwrap_or_else(|| UNKNOWN_DURATION.to_string());
                let player = self.player.clone();
                Some(
                    div().h(px(ROW_HEIGHT + ROW_GAP)).pb(px(ROW_GAP)).child(
                        div()
                            .id(("playlist-row", index))
                            .h(px(ROW_HEIGHT))
                            .px(px(8.0))
                            .flex()
                            .items_center()
                            .gap(px(10.0))
                            .rounded(px(14.0))
                            .cursor_pointer()
                            .map(|row| {
                                if is_current {
                                    row.bg(theme.playlist_row_active_bg)
                                } else {
                                    row.hover(|s| s.bg(theme.playlist_row_hover_bg))
                                }
                            })
                            .on_click(move |_, _, cx| {
                                player.update(cx, |player, cx| player.play_index(index, cx))
                            })
                            .child(
                                div()
                                    .flex_1()
                                    .min_w_0()
                                    .flex()
                                    .flex_col()
                                    .gap(px(2.0))
                                    .child(
                                        div()
                                            .truncate()
                                            .text_size(px(13.0))
                                            .font_weight(FontWeight::SEMIBOLD)
                                            .text_color(if is_current {
                                                theme.accent_dark
                                            } else {
                                                theme.text_secondary
                                            })
                                            .child(media_paths::display_name(path)),
                                    )
                                    .child(
                                        div()
                                            .truncate()
                                            .text_size(px(11.0))
                                            .text_color(theme.text_subtle)
                                            .child(local_music),
                                    ),
                            )
                            .child(
                                div()
                                    .flex_none()
                                    .font_family(theme.mono_font_family.clone())
                                    .text_size(px(11.0))
                                    .text_color(theme.text_muted)
                                    .child(duration),
                            ),
                    ),
                )
            })
            .collect()
    }
}

impl Render for PlaylistView {
    fn render(&mut self, _window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.global::<Theme>().clone();
        let count = self.player.read(cx).tracks().len();

        let header = div()
            .flex_none()
            .h(px(HEADER_HEIGHT))
            .px(px(18.0))
            .flex()
            .items_center()
            .gap(px(8.0))
            .window_control_area(WindowControlArea::Drag)
            .child(
                div()
                    .flex_1()
                    .text_size(px(16.0))
                    .font_weight(FontWeight::SEMIBOLD)
                    .text_color(theme.text_primary)
                    .child(t(cx, Key::Playlist)),
            )
            .child(
                IconButton::new("playlist-open", Icon::FolderOpen)
                    .size(30.0, 14.0)
                    .hover_bg(theme.button_hover_bg)
                    .icon_opacity(0.6)
                    .on_click(cx.listener(|_, _, _, cx| cx.emit(PlaylistEvent::OpenFiles))),
            )
            .child(
                IconButton::new("playlist-close", Icon::X)
                    .size(30.0, 12.0)
                    .hover_bg(theme.close_hover_bg)
                    .icon_opacity(0.6)
                    .on_click(cx.listener(|_, _, _, cx| cx.emit(PlaylistEvent::Close))),
            );

        let body = if count == 0 {
            div()
                .flex_1()
                .flex()
                .flex_col()
                .items_center()
                .justify_center()
                .gap(px(10.0))
                .child(svg().path(Icon::ListMusic.path()).size(px(32.0)).text_color(theme.text_muted))
                .child(
                    div()
                        .text_size(px(14.0))
                        .font_weight(FontWeight::SEMIBOLD)
                        .text_color(theme.text_secondary)
                        .child(t(cx, Key::PlaylistEmpty)),
                )
                .child(
                    div()
                        .text_size(px(12.0))
                        .text_color(theme.text_muted)
                        .child(t(cx, Key::PlaylistEmptyHint)),
                )
                .into_any_element()
        } else {
            uniform_list(
                "playlist",
                count,
                cx.processor(|this, range, _window, cx| this.render_rows(range, cx)),
            )
            .track_scroll(self.scroll.clone())
            .flex_1()
            .px(px(16.0))
            .pt(px(16.0))
            .pb(px(10.0))
            .into_any_element()
        };

        div().size_full().flex().flex_col().occlude().child(header).child(body)
    }
}
