//! The bass / mid / treble card shown over the full player.

use gpui::{
    App, Entity, FontWeight, InteractiveElement, IntoElement, ParentElement, RenderOnce, Styled, Window, div,
    px,
};
use player_core::eq::{Band, LEVEL_MAX};
use player_core::i18n::Key;

use crate::model::PlayerModel;
use crate::ui::t;
use crate::ui::theme::Theme;
use crate::ui::widgets::Slider;

#[derive(IntoElement)]
pub struct EqPanel {
    player: Entity<PlayerModel>,
}

impl EqPanel {
    pub fn new(player: Entity<PlayerModel>) -> Self {
        Self { player }
    }
}

impl RenderOnce for EqPanel {
    fn render(self, _window: &mut Window, cx: &mut App) -> impl IntoElement {
        let theme = cx.global::<Theme>().clone();
        let levels = self.player.read(cx).eq();
        let band = |band: Band, label: Key| {
            let player = self.player.clone();
            div()
                .flex()
                .flex_col()
                .items_center()
                .gap(px(6.0))
                .child(
                    div().h(px(96.0)).child(
                        Slider::new(("eq-band", band.index()), levels.get(band) as f32 / LEVEL_MAX as f32)
                            .vertical()
                            .handle_size(14.0)
                            .handle_color(theme.track_fill)
                            .always_show_handle()
                            .live()
                            .on_change(move |value, _, cx| {
                                let level = (value * LEVEL_MAX as f32).round() as u8;
                                player.update(cx, |player, cx| player.set_eq_level(band, level, cx));
                            }),
                    ),
                )
                .child(div().text_size(px(10.0)).text_color(theme.text_muted).child(t(cx, label)))
        };

        div()
            .w(px(240.0))
            .h(px(160.0))
            .p(px(14.0))
            .flex()
            .flex_col()
            .gap(px(8.0))
            .rounded(px(18.0))
            .bg(theme.surface_panel_bg)
            .border_1()
            .border_color(theme.surface_panel_border)
            .occlude()
            .child(
                div()
                    .text_size(px(12.0))
                    .font_weight(FontWeight::SEMIBOLD)
                    .text_color(theme.text_primary)
                    .child(t(cx, Key::Equalizer)),
            )
            .child(
                div()
                    .flex()
                    .justify_center()
                    .gap(px(36.0))
                    .child(band(Band::Bass, Key::Bass))
                    .child(band(Band::Mid, Key::Mid))
                    .child(band(Band::Treble, Key::Treble)),
            )
    }
}
