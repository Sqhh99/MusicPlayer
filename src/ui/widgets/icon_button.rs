use gpui::{
    App, ClickEvent, ElementId, Hsla, InteractiveElement, IntoElement, ParentElement, RenderOnce,
    StatefulInteractiveElement, Styled, Window, div, prelude::FluentBuilder, px, svg,
};

use crate::ui::icons::Icon;
use crate::ui::theme::Theme;

type ClickHandler = Box<dyn Fn(&ClickEvent, &mut Window, &mut App) + 'static>;

/// A square, icon-only button with hover/pressed/active backgrounds.
#[derive(IntoElement)]
pub struct IconButton {
    id: ElementId,
    icon: Icon,
    size: f32,
    icon_size: f32,
    active: bool,
    hover_bg: Option<Hsla>,
    icon_opacity: Option<f32>,
    bordered: bool,
    on_click: Option<ClickHandler>,
}

impl IconButton {
    pub fn new(id: impl Into<ElementId>, icon: Icon) -> Self {
        Self {
            id: id.into(),
            icon,
            size: 34.0,
            icon_size: 16.0,
            active: false,
            hover_bg: None,
            icon_opacity: None,
            bordered: false,
            on_click: None,
        }
    }

    pub fn size(mut self, size: f32, icon_size: f32) -> Self {
        self.size = size;
        self.icon_size = icon_size;
        self
    }

    /// Toggled-on state: accent-tinted icon on a soft accent background.
    pub fn active(mut self, active: bool) -> Self {
        self.active = active;
        self
    }

    pub fn hover_bg(mut self, color: Hsla) -> Self {
        self.hover_bg = Some(color);
        self
    }

    pub fn icon_opacity(mut self, opacity: f32) -> Self {
        self.icon_opacity = Some(opacity);
        self
    }

    pub fn bordered(mut self) -> Self {
        self.bordered = true;
        self
    }

    pub fn on_click(mut self, handler: impl Fn(&ClickEvent, &mut Window, &mut App) + 'static) -> Self {
        self.on_click = Some(Box::new(handler));
        self
    }
}

impl RenderOnce for IconButton {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.global::<Theme>();
        let radius = (self.size * 0.25).round().max(8.0);
        let rest_opacity = self.icon_opacity.unwrap_or(theme.icon_opacity);
        let (icon_color, opacity) = if self.active {
            (theme.icon_active, theme.icon_strong_opacity)
        } else {
            (theme.icon, rest_opacity)
        };
        let hover_opacity = if self.active { opacity } else { (rest_opacity + 0.3).min(1.0) };
        let hover_bg = self.hover_bg.unwrap_or(gpui::transparent_black());
        let pressed_bg = theme.button_pressed_bg;
        let group = format!("icon-button-{}", self.id);

        div()
            .id(self.id)
            .group(group.clone())
            .flex_none()
            .size(px(self.size))
            .flex()
            .items_center()
            .justify_center()
            .rounded(px(radius))
            .cursor_pointer()
            .occlude()
            .when(self.bordered, |el| el.border_1().border_color(theme.button_border))
            .when(self.active, |el| el.bg(theme.accent_soft))
            .when(!self.active, |el| el.hover(|s| s.bg(hover_bg)).active(|s| s.bg(pressed_bg)))
            .child(
                svg()
                    .path(self.icon.path())
                    .size(px(self.icon_size))
                    .text_color(icon_color.opacity(opacity))
                    .group_hover(group, |s| s.text_color(icon_color.opacity(hover_opacity))),
            )
            .when_some(self.on_click, |el, handler| el.on_click(handler))
    }
}
