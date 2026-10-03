//! Settings overlay: theme, language, material strengths and background glow.

use std::rc::Rc;

use gpui::{
    App, Entity, FontWeight, InteractiveElement, IntoElement, ParentElement, RenderOnce,
    StatefulInteractiveElement, Styled, Window, WindowControlArea, div, px, svg,
};
use player_core::i18n::{Key, Lang};
use player_core::settings::{Settings, ThemeMode};

use crate::model::SettingsModel;
use crate::ui::icons::Icon;
use crate::ui::t;
use crate::ui::theme::Theme;
use crate::ui::widgets::{IconButton, Slider, Toggle};

const SIDEBAR_WIDTH: f32 = 190.0;
const HEADER_HEIGHT: f32 = 56.0;
const SECTION_INSET: f32 = 24.0;

type CloseHandler = Rc<dyn Fn(&mut Window, &mut App)>;

#[derive(IntoElement)]
pub struct SettingsPanel {
    settings: Entity<SettingsModel>,
    /// The window's corner radius, so the sidebar background follows its left corners.
    radius: f32,
    on_close: CloseHandler,
}

impl SettingsPanel {
    pub fn new(
        settings: Entity<SettingsModel>,
        radius: f32,
        on_close: impl Fn(&mut Window, &mut App) + 'static,
    ) -> Self {
        Self { settings, radius, on_close: Rc::new(on_close) }
    }
}

fn update(settings: &Entity<SettingsModel>, cx: &mut App, change: impl FnOnce(&mut Settings)) {
    settings.update(cx, |model, cx| model.update(cx, change));
}

fn section_title(text: &'static str, theme: &Theme) -> impl IntoElement {
    div().text_size(px(16.0)).font_weight(FontWeight::SEMIBOLD).text_color(theme.text_primary).child(text)
}

/// A selectable card with a title and a hint line.
fn choice_card(
    id: &'static str,
    title: &'static str,
    hint: Option<&'static str>,
    selected: bool,
    theme: &Theme,
    on_select: impl Fn(&mut App) + 'static,
) -> impl IntoElement {
    div()
        .id(id)
        .w(px(190.0))
        .h(px(if hint.is_some() { 104.0 } else { 56.0 }))
        .px(px(16.0))
        .flex()
        .flex_col()
        .justify_center()
        .gap(px(6.0))
        .rounded(px(18.0))
        .border_1()
        .border_color(if selected { theme.accent } else { theme.surface_panel_border })
        .bg(if selected { theme.button_active_bg } else { theme.surface_panel_bg })
        .cursor_pointer()
        .on_click(move |_, _, cx| on_select(cx))
        .child(
            div()
                .text_size(px(15.0))
                .font_weight(FontWeight::SEMIBOLD)
                .text_color(theme.text_primary)
                .child(title),
        )
        .children(hint.map(|hint| div().text_size(px(12.0)).text_color(theme.text_subtle).child(hint)))
}

fn strength_slider(
    id: &'static str,
    label: &'static str,
    value: u8,
    theme: &Theme,
    on_change: impl Fn(u8, &mut App) + 'static,
) -> impl IntoElement {
    div()
        .flex()
        .flex_col()
        .gap(px(8.0))
        .child(div().text_size(px(14.0)).text_color(theme.text_secondary).child(label))
        .child(
            Slider::new(id, value as f32 / 100.0)
                .fill(theme.accent)
                .handle_size(18.0)
                .handle_border()
                .always_show_handle()
                .live()
                .on_change(move |fraction, _, cx| on_change((fraction * 100.0).round() as u8, cx)),
        )
        .child(
            div()
                .font_family(theme.mono_font_family.clone())
                .text_size(px(12.0))
                .text_color(theme.text_muted)
                .child(format!("{value}%")),
        )
}

impl RenderOnce for SettingsPanel {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.global::<Theme>().clone();
        let ui = self.settings.read(cx).get().ui.clone();
        let settings = self.settings;

        let sidebar = div()
            .flex_none()
            .w(px(SIDEBAR_WIDTH))
            .h_full()
            .p(px(16.0))
            .flex()
            .flex_col()
            .gap(px(18.0))
            .rounded_l(px(self.radius))
            .bg(theme.surface_panel_bg)
            .child(
                div()
                    .text_size(px(24.0))
                    .font_weight(FontWeight::SEMIBOLD)
                    .text_color(theme.text_primary)
                    .child(t(cx, Key::Settings)),
            )
            .child(
                div()
                    .h(px(46.0))
                    .px(px(14.0))
                    .flex()
                    .items_center()
                    .gap(px(10.0))
                    .rounded(px(14.0))
                    .bg(theme.button_active_bg)
                    .border_1()
                    .border_color(theme.button_border)
                    .child(svg().path(Icon::Monitor.path()).size(px(16.0)).text_color(theme.icon))
                    .child(
                        div()
                            .text_size(px(14.0))
                            .font_weight(FontWeight::SEMIBOLD)
                            .text_color(theme.text_primary)
                            .child(t(cx, Key::Interface)),
                    ),
            );

        let on_close = self.on_close.clone();
        let header = div()
            .flex_none()
            .h(px(HEADER_HEIGHT))
            .px(px(18.0))
            .flex()
            .items_center()
            .justify_end()
            .window_control_area(WindowControlArea::Drag)
            .child(
                IconButton::new("settings-close", Icon::X)
                    .size(30.0, 12.0)
                    .hover_bg(theme.close_hover_bg)
                    .icon_opacity(0.6)
                    .on_click(move |_, window, cx| on_close(window, cx)),
            );

        let themes = [
            ("theme-day", ThemeMode::Day, Key::ThemeDay, Key::ThemeDayHint),
            ("theme-night", ThemeMode::Night, Key::ThemeNight, Key::ThemeNightHint),
        ];
        let theme_section =
            div().flex().flex_col().gap(px(14.0)).child(section_title(t(cx, Key::Theme), &theme)).child(
                div().flex().gap(px(14.0)).children(themes.map(|(id, mode, title, hint)| {
                    let settings = settings.clone();
                    choice_card(id, t(cx, title), Some(t(cx, hint)), ui.theme == mode, &theme, move |cx| {
                        update(&settings, cx, |s| s.ui.theme = mode)
                    })
                })),
            );

        let language_section = div()
            .flex()
            .flex_col()
            .gap(px(14.0))
            .child(section_title(t(cx, Key::Language), &theme))
            .child(div().text_size(px(12.0)).text_color(theme.text_muted).child(t(cx, Key::LanguageHint)))
            .child(div().flex().gap(px(14.0)).children(Lang::ALL.map(|lang| {
                let settings = settings.clone();
                let id = match lang {
                    Lang::Zh => "lang-zh",
                    Lang::En => "lang-en",
                };
                choice_card(id, lang.native_name(), None, ui.language == lang, &theme, move |cx| {
                    update(&settings, cx, |s| s.ui.language = lang)
                })
            })));

        let glow_settings = settings.clone();
        let material_section = div()
            .flex()
            .flex_col()
            .gap(px(18.0))
            .child(section_title(t(cx, Key::Material), &theme))
            .child(strength_slider("material", t(cx, Key::SurfaceMaterial), ui.material_strength, &theme, {
                let settings = settings.clone();
                move |value, cx| update(&settings, cx, |s| s.ui.material_strength = value)
            }))
            .child(strength_slider(
                "button-material",
                t(cx, Key::ButtonMaterial),
                ui.button_material_strength,
                &theme,
                {
                    let settings = settings.clone();
                    move |value, cx| update(&settings, cx, |s| s.ui.button_material_strength = value)
                },
            ))
            .child(
                div()
                    .id("background-glow")
                    .h(px(62.0))
                    .px(px(14.0))
                    .flex()
                    .items_center()
                    .gap(px(12.0))
                    .rounded(px(16.0))
                    .border_1()
                    .border_color(gpui::transparent_black())
                    .cursor_pointer()
                    .hover(|s| s.bg(theme.button_hover_bg).border_color(theme.button_border))
                    .active(|s| s.bg(theme.button_pressed_bg))
                    .on_click(move |_, _, cx| {
                        update(&glow_settings, cx, |s| s.ui.background_glow = !s.ui.background_glow)
                    })
                    .child(
                        div()
                            .flex_1()
                            .flex()
                            .flex_col()
                            .gap(px(4.0))
                            .child(
                                div()
                                    .text_size(px(14.0))
                                    .text_color(theme.text_secondary)
                                    .child(t(cx, Key::BackgroundGlow)),
                            )
                            .child(
                                div()
                                    .text_size(px(12.0))
                                    .text_color(theme.text_muted)
                                    .child(t(cx, Key::BackgroundGlowHint)),
                            ),
                    )
                    .child(Toggle::new(ui.background_glow)),
            );

        let content = div().id("settings-content").flex_1().overflow_y_scroll().child(
            div()
                .p(px(SECTION_INSET))
                .pt(px(4.0))
                .flex()
                .flex_col()
                .gap(px(SECTION_INSET * 2.0))
                .child(theme_section)
                .child(language_section)
                .child(material_section),
        );

        div()
            .size_full()
            .flex()
            .occlude()
            .child(sidebar)
            .child(div().flex_1().h_full().flex().flex_col().child(header).child(content))
    }
}
