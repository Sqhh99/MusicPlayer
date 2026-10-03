//! Cover art with rounded corners, or a gradient placeholder when there is none.

use std::sync::Arc;
use std::time::Duration;

use gpui::{
    Animation, AnimationExt, App, ElementId, Image, IntoElement, ObjectFit, ParentElement, RenderOnce,
    Styled, StyledImage, Window, div, img, linear_color_stop, linear_gradient, px, svg,
};
use player_core::easing;

use crate::ui::icons::Icon;
use crate::ui::theme::Theme;

/// Paused covers shrink slightly, as in the original player.
const PAUSED_SCALE: f32 = 0.96;

#[derive(IntoElement)]
pub struct AlbumArt {
    id: &'static str,
    cover: Option<Arc<Image>>,
    size: f32,
    radius: f32,
    playing: bool,
}

impl AlbumArt {
    pub fn new(id: &'static str, cover: Option<Arc<Image>>, size: f32, radius: f32, playing: bool) -> Self {
        Self { id, cover, size, radius, playing }
    }
}

impl RenderOnce for AlbumArt {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.global::<Theme>();
        let (size, radius) = (self.size, self.radius);

        let face = match self.cover {
            Some(cover) => {
                img(cover).size_full().rounded(px(radius)).object_fit(ObjectFit::Cover).into_any_element()
            }
            None => div()
                .size_full()
                .flex()
                .items_center()
                .justify_center()
                .rounded(px(radius))
                .border_1()
                .border_color(theme.album_placeholder_border)
                .bg(linear_gradient(
                    180.0,
                    linear_color_stop(theme.album_placeholder_start, 0.0),
                    linear_color_stop(theme.album_placeholder_end, 1.0),
                ))
                .child(
                    svg()
                        .path(Icon::Music.path())
                        .size(px((size * 0.28).max(10.0)))
                        .text_color(theme.text_muted.opacity(0.55)),
                )
                .into_any_element(),
        };

        let (from, to) = if self.playing { (PAUSED_SCALE, 1.0) } else { (1.0, PAUSED_SCALE) };
        let inner = div().flex_none().child(face).with_animation(
            ElementId::Name(format!("{}-{}", self.id, self.playing).into()),
            Animation::new(Duration::from_millis(400)).with_easing(easing::out_cubic),
            move |el, delta| el.size(px(size * easing::lerp(from, to, delta))),
        );

        div().flex_none().size(px(size)).flex().items_center().justify_center().child(inner)
    }
}
