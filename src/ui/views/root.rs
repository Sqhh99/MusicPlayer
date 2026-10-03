//! `MainView`: the window's root. Owns UI state (mode, overlays, pin) and composes the
//! full / mini / island layouts with the playlist, settings and EQ overlays on top.

use std::time::{Duration, Instant};

use gpui::{
    AnyElement, App, AppContext, Context, Entity, EventEmitter, FocusHandle, Focusable, InteractiveElement,
    IntoElement, MouseButton, ParentElement, Render, StatefulInteractiveElement, Styled, Task, Window,
    WindowControlArea, div, linear_color_stop, linear_gradient, prelude::FluentBuilder, px, relative, size,
};
use player_core::easing;
use player_core::geometry::Rect;
use player_core::media_paths::{self, AUDIO_EXTENSIONS};

use crate::actions::{
    KEY_CONTEXT, Next, Previous, ToggleEq, ToggleMute, TogglePlay, TogglePlaylist, VolumeDown, VolumeUp,
};
use crate::model::{PlayerModel, SettingsModel};
use crate::platform::NativeWindow;
use crate::ui::anim::Tween;
use crate::ui::icons::Icon;
use crate::ui::t;
use crate::ui::theme::{Theme, metrics};
use crate::ui::views::eq_bars::EqBars;
use crate::ui::views::eq_panel::EqPanel;
use crate::ui::views::island_wave::IslandWave;
use crate::ui::views::lyrics::{LyricsEvent, LyricsView};
use crate::ui::views::playlist::{PlaylistEvent, PlaylistView};
use crate::ui::views::settings::SettingsPanel;
use crate::ui::widgets::IconButton;
use crate::ui::window_mode::{ModeTransition, TRANSITION_DURATION, WindowMode, layer_opacity};

const CONTROLS_HIDE_DELAY: Duration = Duration::from_secs(2);
const FRAME: Duration = Duration::from_millis(8);

/// Notifications for the app shell (tray labels follow window visibility).
pub enum MainViewEvent {
    VisibilityChanged,
}

pub struct MainView {
    pub(super) player: Entity<PlayerModel>,
    settings: Entity<SettingsModel>,
    focus: FocusHandle,
    native: Option<NativeWindow>,
    window_visible: bool,

    pub(super) mode: WindowMode,
    transition: Option<ModeTransition>,
    transition_task: Option<Task<()>>,
    pinned: bool,

    pub(super) show_lyrics: bool,
    saved_lyrics: bool,
    pending_settings: bool,
    pub(super) show_eq: bool,
    pub(super) playlist_open: bool,
    settings_open: bool,

    playlist_anim: Tween,
    settings_anim: Tween,
    eq_anim: Tween,
    pub(super) lyrics_anim: Tween,
    controls_anim: Tween,
    hide_controls_task: Option<Task<()>>,

    pub(super) lyrics: Entity<LyricsView>,
    playlist: Entity<PlaylistView>,
    pub(super) eq_bars: Entity<EqBars>,
    pub(super) island_wave: Entity<IslandWave>,
    open_files_task: Option<Task<()>>,
}

impl EventEmitter<MainViewEvent> for MainView {}

impl Focusable for MainView {
    fn focus_handle(&self, _cx: &App) -> FocusHandle {
        self.focus.clone()
    }
}

impl MainView {
    pub fn new(
        player: Entity<PlayerModel>,
        settings: Entity<SettingsModel>,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> Self {
        let lyrics = cx.new(|cx| LyricsView::new(&player, cx));
        let playlist = cx.new(|cx| PlaylistView::new(player.clone(), cx));
        let eq_bars = cx.new(|cx| EqBars::new(&player, cx));
        let island_wave = cx.new(|cx| IslandWave::new(&player, cx));

        cx.observe(&player, |_, _, cx| cx.notify()).detach();
        cx.observe(&settings, |_, _, cx| cx.notify()).detach();
        cx.subscribe_in(&lyrics, window, |this, _, event, window, cx| match event {
            LyricsEvent::Close => this.toggle_lyrics(window, cx),
        })
        .detach();
        cx.subscribe_in(&playlist, window, |this, _, event, _, cx| match event {
            PlaylistEvent::Close => this.set_playlist_open(false, cx),
            PlaylistEvent::OpenFiles => this.open_files(cx),
        })
        .detach();

        let focus = cx.focus_handle();
        window.focus(&focus);

        Self {
            player,
            settings,
            focus,
            native: NativeWindow::from_window(window),
            window_visible: true,
            mode: WindowMode::Full,
            transition: None,
            transition_task: None,
            pinned: false,
            show_lyrics: false,
            saved_lyrics: false,
            pending_settings: false,
            show_eq: false,
            playlist_open: false,
            settings_open: false,
            playlist_anim: Tween::settled(0.0),
            settings_anim: Tween::settled(0.0),
            eq_anim: Tween::settled(0.0),
            lyrics_anim: Tween::settled(0.0),
            controls_anim: Tween::settled(1.0),
            hide_controls_task: None,
            lyrics,
            playlist,
            eq_bars,
            island_wave,
            open_files_task: None,
        }
    }

    pub fn native(&self) -> Option<NativeWindow> {
        self.native
    }

    pub fn is_window_visible(&self) -> bool {
        self.window_visible
    }

    // ── Window visibility ───────────────────────────────────────────────────

    pub fn show_window(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if let Some(native) = self.native {
            let island =
                (self.mode == WindowMode::Island).then(|| self.island_rect(native, window)).flatten();
            native.defer(cx, move |native| {
                native.show();
                if let Some(rect) = island {
                    native.set_client_rect(rect);
                }
            });
        }
        window.activate_window();
        window.focus(&self.focus);
        self.set_window_visible(true, cx);
    }

    /// Hides to the tray. Without native support the window is minimized instead.
    pub fn hide_window(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        match self.native {
            Some(native) => native.defer(cx, NativeWindow::hide),
            None => window.minimize_window(),
        }
        self.set_window_visible(false, cx);
    }

    pub fn toggle_window(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let visible = self.native.map_or(self.window_visible, NativeWindow::is_visible);
        if visible {
            self.hide_window(window, cx);
        } else {
            self.show_window(window, cx);
        }
    }

    fn set_window_visible(&mut self, visible: bool, cx: &mut Context<Self>) {
        self.window_visible = visible;
        cx.emit(MainViewEvent::VisibilityChanged);
    }

    fn set_pinned(&mut self, pinned: bool, cx: &mut Context<Self>) {
        self.pinned = pinned;
        if let Some(native) = self.native {
            native.defer(cx, move |native| native.set_topmost(pinned));
        }
        cx.notify();
    }

    // ── Panels ──────────────────────────────────────────────────────────────

    fn close_transient_panels(&mut self, cx: &mut Context<Self>) {
        self.set_playlist_open(false, cx);
        self.set_settings_open(false, cx);
        self.set_eq_open(false, cx);
    }

    pub(super) fn set_playlist_open(&mut self, open: bool, cx: &mut Context<Self>) {
        if open && self.mode != WindowMode::Full {
            return;
        }
        self.playlist_open = open;
        if open {
            self.set_settings_open(false, cx);
            self.set_eq_open(false, cx);
            self.playlist.read(cx).reveal_current(cx);
        }
        self.playlist_anim.animate_to(open as u8 as f32, Duration::from_millis(320), easing::in_out_quad);
        cx.notify();
    }

    fn set_settings_open(&mut self, open: bool, cx: &mut Context<Self>) {
        self.settings_open = open;
        if open {
            self.set_playlist_open(false, cx);
            self.set_eq_open(false, cx);
        }
        self.settings_anim.animate_to(open as u8 as f32, Duration::from_millis(220), easing::in_out_quad);
        cx.notify();
    }

    pub(super) fn set_eq_open(&mut self, open: bool, cx: &mut Context<Self>) {
        let open = open && self.mode == WindowMode::Full;
        self.show_eq = open;
        self.eq_anim.animate_to(open as u8 as f32, Duration::from_millis(200), easing::out_quad);
        cx.notify();
    }

    pub(super) fn toggle_eq(&mut self, cx: &mut Context<Self>) {
        if !self.show_eq && self.show_lyrics {
            self.set_lyrics(false, cx);
        }
        self.set_eq_open(!self.show_eq, cx);
    }

    fn set_lyrics(&mut self, show: bool, cx: &mut Context<Self>) {
        self.show_lyrics = show;
        if show {
            self.set_eq_open(false, cx);
        }
        self.lyrics.update(cx, |lyrics, cx| lyrics.set_visible(show, cx));
        self.lyrics_anim.animate_to(show as u8 as f32, Duration::from_millis(200), easing::out_quad);
        cx.notify();
    }

    pub(super) fn toggle_lyrics(&mut self, _window: &mut Window, cx: &mut Context<Self>) {
        self.set_lyrics(!self.show_lyrics, cx);
    }

    fn open_settings(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        if self.mode != WindowMode::Full {
            self.pending_settings = true;
            self.switch_mode(WindowMode::Full, window, cx);
            return;
        }
        self.pending_settings = false;
        self.close_transient_panels(cx);
        self.set_settings_open(true, cx);
    }

    pub(super) fn open_files(&mut self, cx: &mut Context<Self>) {
        let start_dir = self
            .settings
            .read(cx)
            .get()
            .last_dir
            .clone()
            .filter(|dir| dir.is_dir())
            .or_else(|| directories::UserDirs::new().and_then(|dirs| dirs.audio_dir().map(Into::into)));
        let mut dialog = rfd::FileDialog::new()
            .set_title(t(cx, player_core::i18n::Key::OpenFiles))
            .add_filter(t(cx, player_core::i18n::Key::AudioFiles), AUDIO_EXTENSIONS);
        // Never pass GPUI's `Window` here; see `NativeWindow::dialog_parent`.
        if let Some(native) = self.native {
            dialog = dialog.set_parent(&native.dialog_parent());
        }
        if let Some(dir) = start_dir {
            dialog = dialog.set_directory(dir);
        }
        let player = self.player.clone();
        let settings = self.settings.clone();
        // The dialog runs modally on the UI thread (as GPUI's own file prompt does), from a
        // task that doesn't hold the app borrowed, so its message loop keeps the window alive.
        self.open_files_task = Some(cx.spawn(async move |_, cx| {
            let Some(files) = dialog.pick_files() else { return };
            let tracks: Vec<_> = files.into_iter().filter(|path| media_paths::is_audio_file(path)).collect();
            let Some(folder) = tracks.first().and_then(|first| first.parent()).map(Into::into) else {
                return;
            };
            cx.update(|cx| {
                settings.update(cx, |settings, cx| settings.update(cx, |s| s.last_dir = Some(folder)));
                player.update(cx, |player, cx| player.set_tracks(tracks, cx));
            })
            .ok();
        }));
    }

    // ── Modes ───────────────────────────────────────────────────────────────

    fn toggle_mini(&mut self, window: &mut Window, cx: &mut Context<Self>) {
        let target = if self.mode == WindowMode::Mini { WindowMode::Full } else { WindowMode::Mini };
        self.switch_mode(target, window, cx);
    }

    fn island_rect(&self, native: NativeWindow, window: &Window) -> Option<Rect> {
        let monitor = native.monitor_rect()?;
        let scale = window.scale_factor();
        let (w, h) = WindowMode::Island.size();
        Some(monitor.top_centered(
            (w * scale).round() as i32,
            (h * scale).round() as i32,
            (metrics::ISLAND_TOP_MARGIN * scale).round() as i32,
        ))
    }

    /// Animates the window into another mode: bounds, corner radius and a content cross-fade.
    pub(super) fn switch_mode(&mut self, to: WindowMode, window: &mut Window, cx: &mut Context<Self>) {
        if self.mode == to || self.transition.is_some() {
            return;
        }
        let from = self.mode;
        if from == WindowMode::Full {
            self.saved_lyrics = self.show_lyrics;
        }
        if to != WindowMode::Full {
            self.pending_settings = false;
            self.close_transient_panels(cx);
            self.set_lyrics(false, cx);
            self.lyrics_anim.jump_to(0.0);
        }
        if to == WindowMode::Island {
            self.set_pinned(true, cx);
        }
        NativeWindow::set_edge_snapping(false);

        let scale = window.scale_factor();
        let (width, height) = to.size();
        let native = self.native;
        let placement = native.and_then(|native| {
            let current = native.client_rect()?;
            let monitor = native.monitor_rect()?;
            let (w, h) = ((width * scale).round() as i32, (height * scale).round() as i32);
            let target = match (from, to) {
                (_, WindowMode::Island) => self.island_rect(native, window)?,
                (WindowMode::Island, _) => monitor.centered(w, h),
                _ => Rect::new(current.x, current.y, w, h).clamped_within(&monitor),
            };
            Some((native, current, target))
        });
        let start_size = window.viewport_size();

        self.transition = Some(ModeTransition { from, to, progress: 0.0 });
        self.transition_task = Some(cx.spawn_in(window, async move |this, cx| {
            let start = Instant::now();
            loop {
                let t = (start.elapsed().as_secs_f32() / TRANSITION_DURATION.as_secs_f32()).min(1.0);
                let eased = easing::in_out_cubic(t);
                // Outside of `update`: resizing re-enters the window procedure synchronously.
                if let Some((native, from_rect, to_rect)) = placement {
                    native.set_client_rect(from_rect.lerp(&to_rect, eased));
                }
                let updated = this.update_in(cx, |view, window, cx| {
                    if placement.is_none() {
                        let lerp = |a: gpui::Pixels, b: f32| px(easing::lerp(a / px(1.0), b, eased));
                        window.resize(size(lerp(start_size.width, width), lerp(start_size.height, height)));
                    }
                    if let Some(transition) = &mut view.transition {
                        transition.progress = eased;
                    }
                    if t >= 1.0 {
                        view.finish_transition(cx);
                    }
                    cx.notify();
                });
                if updated.is_err() || t >= 1.0 {
                    break;
                }
                cx.background_executor().timer(FRAME).await;
            }
        }));
        cx.notify();
    }

    fn finish_transition(&mut self, cx: &mut Context<Self>) {
        let Some(transition) = self.transition.take() else { return };
        self.mode = transition.to;
        NativeWindow::set_edge_snapping(self.mode == WindowMode::Mini);
        if self.mode == WindowMode::Full {
            if self.pending_settings {
                self.pending_settings = false;
                self.close_transient_panels(cx);
                self.set_settings_open(true, cx);
            } else if self.saved_lyrics && !self.settings_open {
                self.set_lyrics(true, cx);
            }
        }
    }

    // ── Window controls ─────────────────────────────────────────────────────

    fn on_controls_hover(&mut self, hovered: bool, cx: &mut Context<Self>) {
        if hovered {
            self.hide_controls_task = None;
            self.controls_anim.animate_to(1.0, Duration::from_millis(300), easing::in_out_quad);
            cx.notify();
        } else {
            self.hide_controls_task = Some(cx.spawn(async move |this, cx| {
                cx.background_executor().timer(CONTROLS_HIDE_DELAY).await;
                this.update(cx, |view, cx| {
                    view.controls_anim.animate_to(0.0, Duration::from_millis(300), easing::in_out_quad);
                    cx.notify();
                })
                .ok();
            }));
        }
    }

    fn render_window_controls(&mut self, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.global::<Theme>().clone();
        let mini = self.mode == WindowMode::Mini;
        let button = |id: &'static str, icon: Icon| {
            IconButton::new(id, icon)
                .size(26.0, 12.0)
                .hover_bg(theme.hover_bg)
                .icon_opacity(theme.icon_soft_opacity)
        };
        div()
            .id("window-controls")
            .absolute()
            .top(px(4.0))
            .right(px(6.0))
            .p(px(10.0))
            .flex()
            .gap(px(6.0))
            .opacity(self.controls_anim.value())
            .on_hover(cx.listener(|this, hovered: &bool, _, cx| this.on_controls_hover(*hovered, cx)))
            .child(
                button("mode-mini", if mini { Icon::PictureInPicture2 } else { Icon::PictureInPicture })
                    .on_click(cx.listener(|this, _, window, cx| this.toggle_mini(window, cx))),
            )
            .child(button("mode-island", Icon::Pill).on_click(
                cx.listener(|this, _, window, cx| this.switch_mode(WindowMode::Island, window, cx)),
            ))
            .when(NativeWindow::SUPPORTS_PLACEMENT, |el| {
                el.child(
                    button("pin", Icon::Pin)
                        .active(self.pinned)
                        .icon_opacity(theme.icon_muted_opacity)
                        .on_click(cx.listener(|this, _, _, cx| this.set_pinned(!this.pinned, cx))),
                )
            })
            .child(
                button("settings", Icon::Settings)
                    .active(self.settings_open)
                    .on_click(cx.listener(|this, _, window, cx| this.open_settings(window, cx))),
            )
            .child(button("minimize", Icon::Minus).on_click(|_, window, _| window.minimize_window()))
            .child(
                button("close", Icon::X)
                    .hover_bg(theme.close_hover_bg)
                    .on_click(cx.listener(|this, _, window, cx| this.hide_window(window, cx))),
            )
    }

    fn render_drag_strip(&self) -> impl IntoElement {
        div()
            .id("drag-strip")
            .absolute()
            .top_0()
            .left_0()
            .right_0()
            .h(px(metrics::DRAG_HEIGHT))
            .window_control_area(WindowControlArea::Drag)
            .on_mouse_down(MouseButton::Left, |_, window, _| {
                if !NativeWindow::SUPPORTS_PLACEMENT {
                    window.start_window_move();
                }
            })
    }

    fn render_surface(&self, island: bool, radius: f32, theme: &Theme) -> impl IntoElement {
        let (top, bottom) = if island {
            (theme.island_highlight, theme.island_bottom_tint)
        } else {
            (theme.surface_highlight, theme.surface_bottom_tint)
        };
        let mini = self.mode == WindowMode::Mini;
        // Soft glows: a small blob blurred by its own shadow, kept clear of the corners so
        // the transparent window corners are never tinted.
        let glow = |left: f32, top: f32, width: f32, height: f32, color: gpui::Hsla| {
            div()
                .absolute()
                .left(px(left))
                .top(px(top))
                .w(px(width))
                .h(px(height))
                .rounded_full()
                .bg(color)
                .shadow(vec![gpui::BoxShadow {
                    color,
                    offset: gpui::point(px(0.0), px(0.0)),
                    blur_radius: px(width * 0.6),
                    spread_radius: px(width * 0.15),
                }])
        };

        // One full-size layer: GPUI clamps corner radii to half the element's height, so
        // splitting the gradient into short bands would square off the island's ends.
        div()
            .absolute()
            .size_full()
            .rounded(px(radius))
            .bg(linear_gradient(180.0, linear_color_stop(top, 0.0), linear_color_stop(bottom, 1.0)))
            .when(!island && mini, |el| {
                el.child(glow(30.0, 20.0, 90.0, 50.0, theme.surface_glow_blue)).child(glow(
                    240.0,
                    70.0,
                    70.0,
                    70.0,
                    theme.surface_glow_rose,
                ))
            })
            .when(!island && !mini, |el| {
                el.child(glow(70.0, 50.0, 160.0, 110.0, theme.surface_glow_blue)).child(glow(
                    360.0,
                    140.0,
                    130.0,
                    130.0,
                    theme.surface_glow_rose,
                ))
            })
    }

    fn render_mode_layer(
        &mut self,
        layer: WindowMode,
        window: &mut Window,
        cx: &mut Context<Self>,
    ) -> Option<AnyElement> {
        let mut opacity = layer_opacity(layer, self.mode, self.transition.as_ref());
        // Hide content fully covered by an opaque overlay.
        if self.settings_anim.value() >= 1.0
            || (layer == WindowMode::Full && self.playlist_anim.value() >= 1.0)
        {
            opacity = 0.0;
        }
        if opacity <= 0.0 {
            return None;
        }
        let (width, height) = layer.size();
        let content = match layer {
            WindowMode::Full => self.render_full(window, cx).into_any_element(),
            WindowMode::Mini => self.render_mini(cx).into_any_element(),
            WindowMode::Island => self.render_island(cx).into_any_element(),
        };
        let positioned = div().absolute().w(px(width)).h(px(height)).opacity(opacity).child(content);
        // The island is centered in whatever the window currently is; the others hang from
        // the top-left so they are revealed, not squeezed, while the window grows.
        Some(if layer == WindowMode::Island {
            div()
                .absolute()
                .size_full()
                .flex()
                .items_center()
                .justify_center()
                .child(positioned.relative())
                .into_any_element()
        } else {
            positioned.top_0().left_0().into_any_element()
        })
    }
}

impl Render for MainView {
    fn render(&mut self, window: &mut Window, cx: &mut Context<Self>) -> impl IntoElement {
        let theme = cx.global::<Theme>().clone();
        let animating =
            [&self.playlist_anim, &self.settings_anim, &self.eq_anim, &self.lyrics_anim, &self.controls_anim]
                .iter()
                .any(|tween| tween.is_running());
        if animating {
            window.request_animation_frame();
        }

        let island_shell =
            self.transition.as_ref().map_or(self.mode == WindowMode::Island, ModeTransition::island_shell);
        let radius =
            self.transition.as_ref().map_or(self.mode.corner_radius(), ModeTransition::corner_radius);

        let layers: Vec<AnyElement> = [WindowMode::Full, WindowMode::Mini, WindowMode::Island]
            .into_iter()
            .filter_map(|layer| self.render_mode_layer(layer, window, cx))
            .collect();

        let full = self.mode == WindowMode::Full && self.transition.is_none();
        let eq = self.eq_anim.value();
        let playlist = self.playlist_anim.value();
        let settings = self.settings_anim.value();
        let player = self.player.clone();

        let window_width = window.viewport_size().width;
        // Overlays own their (rounded) background; GPUI clips children only to rectangles,
        // so a square background inside would poke out of the window's rounded corners.
        let overlay = |fraction: f32| {
            div()
                .absolute()
                .top_0()
                .bottom_0()
                .right_0()
                .rounded(px(radius))
                .overflow_hidden()
                .bg(theme.surface_overlay_bg)
                .opacity(fraction)
        };

        let show_chrome = self.transition.is_none()
            && self.mode != WindowMode::Island
            && !self.playlist_open
            && !self.settings_open
            && !self.show_eq;

        div()
            .id("main")
            .key_context(KEY_CONTEXT)
            .on_action(
                cx.listener(|this, _: &TogglePlay, _, cx| this.player.update(cx, |p, cx| p.toggle_play(cx))),
            )
            .on_action(
                cx.listener(|this, _: &Previous, _, cx| this.player.update(cx, |p, cx| p.previous(cx))),
            )
            .on_action(cx.listener(|this, _: &Next, _, cx| this.player.update(cx, |p, cx| p.next(cx))))
            .on_action(
                cx.listener(|this, _: &VolumeUp, _, cx| {
                    this.player.update(cx, |p, cx| p.adjust_volume(5, cx))
                }),
            )
            .on_action(cx.listener(|this, _: &VolumeDown, _, cx| {
                this.player.update(cx, |p, cx| p.adjust_volume(-5, cx))
            }))
            .on_action(
                cx.listener(|this, _: &ToggleMute, _, cx| this.player.update(cx, |p, cx| p.toggle_mute(cx))),
            )
            .on_action(
                cx.listener(|this, _: &TogglePlaylist, _, cx| {
                    this.set_playlist_open(!this.playlist_open, cx)
                }),
            )
            .on_action(cx.listener(|this, _: &ToggleEq, _, cx| this.toggle_eq(cx)))
            .size_full()
            .relative()
            .overflow_hidden()
            .rounded(px(radius))
            .bg(if island_shell { theme.island_bg } else { theme.surface_bg })
            .font_family(theme.font_family.clone())
            .text_color(theme.text_primary)
            // Keyboard focus lives on an invisible child: a focusable element under the cursor
            // claims mouse-downs, which on Windows would also cancel native window dragging.
            .child(div().absolute().size_0().track_focus(&self.focus))
            .child(self.render_surface(island_shell, radius, &theme))
            .children(layers)
            .when(full && eq > 0.0, |el| {
                el.child(
                    div()
                        .id("eq-overlay")
                        .absolute()
                        .size_full()
                        .flex()
                        .items_center()
                        .justify_center()
                        .opacity(eq)
                        .on_click(cx.listener(|this, _, _, cx| this.set_eq_open(false, cx)))
                        .child(EqPanel::new(player)),
                )
            })
            .when(playlist > 0.0, |el| {
                // Slides in from the right: the sheet grows from the right edge and the
                // full-width content rides on its left edge.
                el.child(overlay(playlist).w(relative(playlist)).child(
                    div().absolute().top_0().bottom_0().left_0().w(window_width).child(self.playlist.clone()),
                ))
            })
            .when(settings > 0.0, |el| {
                let view = cx.entity().downgrade();
                el.child(overlay(settings).left_0().child(SettingsPanel::new(
                    self.settings.clone(),
                    radius,
                    move |_, cx| {
                        view.update(cx, |this, cx| this.set_settings_open(false, cx)).ok();
                    },
                )))
            })
            .when(show_chrome, |el| el.child(self.render_drag_strip()).child(self.render_window_controls(cx)))
            // The window outline is drawn last so overlays never cover it.
            .when(!island_shell, |el| {
                el.child(
                    div()
                        .absolute()
                        .size_full()
                        .rounded(px(radius))
                        .border_1()
                        .border_color(theme.surface_border),
                )
            })
    }
}
