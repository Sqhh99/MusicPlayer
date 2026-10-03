use gpui::{App, IntoElement, ParentElement, RenderOnce, Styled, Window, div, px};

use crate::ui::theme::Theme;

/// An on/off switch. Purely visual; the enclosing row handles clicks.
#[derive(IntoElement)]
pub struct Toggle {
    on: bool,
}

impl Toggle {
    pub fn new(on: bool) -> Self {
        Self { on }
    }
}

impl RenderOnce for Toggle {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.global::<Theme>();
        let knob_x = if self.on { 42.0 - 18.0 - 3.0 - 1.0 } else { 2.0 };
        div()
            .flex_none()
            .relative()
            .w(px(42.0))
            .h(px(24.0))
            .rounded_full()
            .border_1()
            .border_color(if self.on { theme.accent } else { theme.surface_panel_border })
            .bg(if self.on { theme.accent } else { theme.track_bg })
            .child(
                div().absolute().top(px(2.0)).left(px(knob_x)).size(px(18.0)).rounded_full().bg(theme.handle),
            )
    }
}
