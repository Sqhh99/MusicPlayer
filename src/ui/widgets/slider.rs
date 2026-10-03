use std::rc::Rc;

use gpui::{
    App, Bounds, CursorStyle, DispatchPhase, ElementId, Hitbox, HitboxBehavior, Hsla, InteractiveElement,
    IntoElement, MouseButton, MouseDownEvent, MouseMoveEvent, MouseUpEvent, ParentElement, Pixels, Point,
    RenderOnce, Styled, Window, canvas, div, prelude::FluentBuilder, px, relative,
};

use crate::ui::theme::Theme;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Axis {
    Horizontal,
    /// Bottom is 0, top is 1.
    Vertical,
}

type ChangeHandler = Rc<dyn Fn(f32, &mut Window, &mut App)>;

/// Track + fill + round handle. Values are fractions in `0.0..=1.0`.
///
/// By default `on_change` fires once when the drag is released (seek-style). With
/// [`Slider::live`] it also fires continuously while dragging.
#[derive(IntoElement)]
pub struct Slider {
    id: ElementId,
    axis: Axis,
    value: f32,
    thickness: f32,
    handle_size: f32,
    fill: Option<Hsla>,
    handle: Option<Hsla>,
    handle_border: bool,
    always_show_handle: bool,
    live: bool,
    on_change: Option<ChangeHandler>,
}

#[derive(Default)]
struct DragState {
    value: Option<f32>,
}

impl Slider {
    pub fn new(id: impl Into<ElementId>, value: f32) -> Self {
        Self {
            id: id.into(),
            axis: Axis::Horizontal,
            value: if value.is_finite() { value.clamp(0.0, 1.0) } else { 0.0 },
            thickness: 6.0,
            handle_size: 10.0,
            fill: None,
            handle: None,
            handle_border: false,
            always_show_handle: false,
            live: false,
            on_change: None,
        }
    }

    pub fn vertical(mut self) -> Self {
        self.axis = Axis::Vertical;
        self
    }

    pub fn thickness(mut self, thickness: f32) -> Self {
        self.thickness = thickness;
        self
    }

    pub fn handle_size(mut self, size: f32) -> Self {
        self.handle_size = size;
        self
    }

    pub fn fill(mut self, color: Hsla) -> Self {
        self.fill = Some(color);
        self
    }

    pub fn handle_color(mut self, color: Hsla) -> Self {
        self.handle = Some(color);
        self
    }

    pub fn handle_border(mut self) -> Self {
        self.handle_border = true;
        self
    }

    pub fn always_show_handle(mut self) -> Self {
        self.always_show_handle = true;
        self
    }

    pub fn live(mut self) -> Self {
        self.live = true;
        self
    }

    pub fn on_change(mut self, handler: impl Fn(f32, &mut Window, &mut App) + 'static) -> Self {
        self.on_change = Some(Rc::new(handler));
        self
    }
}

impl RenderOnce for Slider {
    fn render(self, window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.global::<Theme>().clone();
        let state = window.use_keyed_state(self.id.clone(), cx, |_, _| DragState::default());
        let dragging = state.read(cx).value.is_some();
        let shown = state.read(cx).value.unwrap_or(self.value);
        let hit_size = self.handle_size.max(self.thickness) + 8.0;
        let group = format!("slider-{}", self.id);
        let horizontal = self.axis == Axis::Horizontal;
        let track_offset = px((hit_size - self.thickness) / 2.0);
        let handle_offset = px((hit_size - self.handle_size) / 2.0);
        let handle_shift = px(-self.handle_size / 2.0);

        let track = div().absolute().rounded_full().bg(theme.track_bg);
        let fill = div().absolute().rounded_full().bg(self.fill.unwrap_or(theme.track_fill));
        let handle = div()
            .absolute()
            .size(px(self.handle_size))
            .rounded_full()
            .bg(self.handle.unwrap_or(theme.handle))
            .when(self.handle_border, |el| el.border_1().border_color(theme.surface_panel_border))
            .when(!(self.always_show_handle || dragging), |el| {
                el.opacity(0.0).group_hover(group.clone(), |s| s.opacity(1.0))
            });

        let (track, fill, handle) = if horizontal {
            (
                track.left_0().right_0().top(track_offset).h(px(self.thickness)),
                fill.left_0().top(track_offset).h(px(self.thickness)).w(relative(shown)),
                handle.top(handle_offset).left(relative(shown)).ml(handle_shift),
            )
        } else {
            (
                track.top_0().bottom_0().left(track_offset).w(px(self.thickness)),
                fill.bottom_0().left(track_offset).w(px(self.thickness)).h(relative(shown)),
                handle.left(handle_offset).bottom(relative(shown)).mb(handle_shift),
            )
        };

        let axis = self.axis;
        let live = self.live;
        let on_change = self.on_change;
        let input = canvas(
            |bounds, window, _| window.insert_hitbox(bounds, HitboxBehavior::Normal),
            move |bounds, hitbox, window, _| {
                window.set_cursor_style(CursorStyle::PointingHand, &hitbox);
                register_drag(bounds, hitbox, axis, live, state, on_change, window);
            },
        )
        .absolute()
        .size_full();

        div()
            .id(self.id)
            .group(group)
            .relative()
            .flex_none()
            .map(|el| if horizontal { el.w_full().h(px(hit_size)) } else { el.h_full().w(px(hit_size)) })
            .child(track)
            .child(fill)
            .child(handle)
            .child(input)
    }
}

fn register_drag(
    bounds: Bounds<Pixels>,
    hitbox: Hitbox,
    axis: Axis,
    live: bool,
    state: gpui::Entity<DragState>,
    on_change: Option<ChangeHandler>,
    window: &mut Window,
) {
    let fraction = move |position: Point<Pixels>| -> f32 {
        let value = match axis {
            Axis::Horizontal => (position.x - bounds.left()) / bounds.size.width,
            Axis::Vertical => 1.0 - (position.y - bounds.top()) / bounds.size.height,
        };
        if value.is_finite() { value.clamp(0.0, 1.0) } else { 0.0 }
    };
    let set = {
        let state = state.clone();
        move |value: Option<f32>, cx: &mut App| {
            state.update(cx, |state, cx| {
                state.value = value;
                cx.notify();
            })
        }
    };

    window.on_mouse_event({
        let set = set.clone();
        let on_change = on_change.clone();
        move |event: &MouseDownEvent, phase, window, cx| {
            if phase != DispatchPhase::Bubble
                || event.button != MouseButton::Left
                || !hitbox.is_hovered(window)
            {
                return;
            }
            let value = fraction(event.position);
            set(Some(value), cx);
            if live && let Some(on_change) = &on_change {
                on_change(value, window, cx);
            }
            cx.stop_propagation();
        }
    });

    window.on_mouse_event({
        let set = set.clone();
        let state = state.clone();
        let on_change = on_change.clone();
        move |event: &MouseMoveEvent, phase, window, cx| {
            if phase != DispatchPhase::Bubble || state.read(cx).value.is_none() {
                return;
            }
            if event.pressed_button != Some(MouseButton::Left) {
                set(None, cx);
                return;
            }
            let value = fraction(event.position);
            set(Some(value), cx);
            if live && let Some(on_change) = &on_change {
                on_change(value, window, cx);
            }
        }
    });

    window.on_mouse_event(move |event: &MouseUpEvent, phase, window, cx| {
        if phase != DispatchPhase::Bubble || event.button != MouseButton::Left {
            return;
        }
        let Some(value) = state.read(cx).value else { return };
        if let Some(on_change) = &on_change {
            on_change(value, window, cx);
        }
        set(None, cx);
    });
}
