//! Scrolling, synchronized lyrics. The current line is highlighted and smoothly kept
//! in the vertical center.

use std::sync::Arc;
use std::time::Duration;

use gpui::{
    Context, Entity, EventEmitter, FontWeight, InteractiveElement, IntoElement, ParentElement, Render,
    ScrollHandle, StatefulInteractiveElement, Styled, Window, div, point, prelude::FluentBuilder, px,
};
use player_core::easing;
use player_core::i18n::Key;
use player_core::lyrics::Lyrics;

use crate::model::PlayerModel;
use crate::ui::anim::Tween;
use crate::ui::icons::Icon;
use crate::ui::t;
use crate::ui::theme::Theme;
use crate::ui::widgets::IconButton;

const SCROLL_DURATION: Duration = Duration::from_millis(300);
const LINE_GAP: f32 = 16.0;
const BACK_BUTTON_SPACE: f32 = 60.0;

pub enum LyricsEvent {
    Close,
}

pub struct LyricsView {
    lyrics: Arc<Lyrics>,
    current: Option<usize>,
    scroll: ScrollHandle,
    /// Animated scroll distance from the top (positive = scrolled down).
    scroll_y: Option<Tween>,
    /// Set when the highlight moved; centering happens after the next layout.
    pending_center: bool,
    visible: bool,
}

impl EventEmitter<LyricsEvent> for LyricsView {}

impl LyricsView {
    pub fn new(player: &Entity<PlayerModel>, cx: &mut Context<Self>) -> Self {
        cx.observe(player, |this, player, cx| {
            let (lyrics, index) = {
                let player = player.read(cx);
                (player.lyrics().clone(), player.lyric_index())
            };
            if !Arc::ptr_eq(&this.lyrics, &lyrics) {
                this.lyrics = lyrics;
                this.current = None;
                this.scroll_y = None;
                this.scroll.set_offset(point(px(0.0), px(0.0)));
                cx.notify();
            }
            if index != this.current {
                this.current = index;
                this.pending_center = true;
                cx.notify();
            }
        })
        .detach();
        let player = player.read(cx);
        Self {
            lyrics: player.lyrics().clone(),
            current: player.lyric_index(),
            scroll: ScrollHandle::new(),
            scroll_y: None,
            pending_center: true,
            visible: false,
        }
    }

    /// Called by the parent when the panel is shown or hidden; recenters on show.
    pub fn set_visible(&mut self, visible: bool, cx: &mut Context<Self>) {
        if visible != self.visible {
            self.visible = visible;
            self.pending_center = visible;
            self.scroll_y = None;
            cx.notify();
        }
    }

    /// Starts scrolling so the current line sits in the middle of the viewport.
    fn center_current_line(&mut self, cx: &mut Context<Self>) {
        let Some(index) = self.current else { return };
        let Some(line) = self.scroll.bounds_for_item(index) else { return };
        let viewport = self.scroll.bounds();
        let offset = self.scroll.offset();
        let max_scroll = self.scroll.max_offset().height / px(1.0);

        let line_center = (line.center().y - viewport.origin.y - offset.y) / px(1.0);
        let target = (line_center - viewport.size.height / px(1.0) / 2.0).clamp(0.0, max_scroll.max(0.0));
        let current = -offset.y / px(1.0);

        let mut tween = Tween::settled(current);
        tween.animate_to(target, SCROLL_DURATION, easing::out_cubic);
        self.scroll_y = Some(tween);
        cx.notify();
    }
}

impl Render for LyricsView {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.global::<Theme>().clone();

        if self.pending_center && self.visible {
            self.pending_center = false;
            let this = cx.entity().downgrade();
            window.on_next_frame(move |_, cx| {
                this.update(cx, |view, cx| view.center_current_line(cx)).ok();
            });
        }
        if let Some(tween) = &self.scroll_y {
            self.scroll.set_offset(point(px(0.0), px(-tween.value())));
            if tween.is_running() {
                window.request_animation_frame();
            } else {
                self.scroll_y = None;
            }
        }

        let body = if self.lyrics.is_empty() {
            div()
                .size_full()
                .flex()
                .items_center()
                .justify_center()
                .text_size(px(13.0))
                .text_color(theme.text_muted)
                .child(t(cx, Key::NoLyrics))
                .into_any_element()
        } else {
            div()
                .id("lyrics-scroll")
                .size_full()
                .overflow_y_scroll()
                .track_scroll(&self.scroll)
                .flex()
                .flex_col()
                .gap(px(LINE_GAP))
                .px(px(16.0))
                .py(px(20.0))
                .font_family(theme.lyrics_font_family.clone())
                .children(self.lyrics.lines.iter().enumerate().map(|(i, line)| {
                    let current = Some(i) == self.current;
                    div()
                        .flex_none()
                        .w_full()
                        .text_center()
                        .map(|line| {
                            if current {
                                line.text_size(px(16.0))
                                    .font_weight(FontWeight::SEMIBOLD)
                                    .text_color(theme.text_primary)
                            } else {
                                line.text_size(px(13.0)).text_color(theme.text_muted.opacity(0.7))
                            }
                        })
                        .child(line.text.clone())
                }))
                .into_any_element()
        };

        div()
            .size_full()
            .relative()
            .child(div().absolute().top_0().left_0().right_0().bottom(px(BACK_BUTTON_SPACE)).child(body))
            .child(
                div().absolute().left_0().right_0().bottom(px(12.0)).flex().justify_center().child(
                    IconButton::new("lyrics-back", Icon::ChevronDown)
                        .bordered()
                        .hover_bg(theme.hover_bg)
                        .icon_opacity(theme.icon_soft_opacity)
                        .on_click(cx.listener(|_, _, _, cx| cx.emit(LyricsEvent::Close))),
                ),
            )
    }
}
