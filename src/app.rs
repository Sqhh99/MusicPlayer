//! Application wiring: models, the main window, tray, single-instance activation and
//! settings persistence.

use std::cell::RefCell;
use std::rc::Rc;

use gpui::{
    App, AppContext, Application, Bounds, Entity, WindowBackgroundAppearance, WindowBounds,
    WindowDecorations, WindowHandle, WindowKind, WindowOptions, px, size,
};

use crate::actions;
use crate::assets::Assets;
use crate::model::{PlayerEvent, PlayerModel, SettingsModel, Status};
use crate::platform::single_instance::{self, Instance};
use crate::platform::tray::{Tray, TrayAction, TrayState};
use crate::ui::Locale;
use crate::ui::theme::{Theme, metrics};
use crate::ui::views::{MainView, MainViewEvent};

/// Requests that arrive from outside the window (tray menu, a second launch).
#[derive(Debug, Clone, Copy)]
enum AppCommand {
    Tray(TrayAction),
    Activate,
}

pub fn run() {
    let listener = match single_instance::acquire() {
        Instance::Primary(listener) => listener,
        Instance::Secondary => {
            log::info!("already running; asked the existing window to show itself");
            return;
        }
    };

    Application::new().with_assets(Assets).run(move |cx: &mut App| {
        if let Err(err) = init(listener, cx) {
            log::error!("failed to start: {err:#}");
            cx.quit();
        }
    });
}

fn init(listener: Option<interprocess::local_socket::Listener>, cx: &mut App) -> anyhow::Result<()> {
    let settings = cx.new(|_| SettingsModel::load());
    let initial = settings.read(cx).get().clone();
    apply_ui_settings(&settings, cx);
    cx.observe(&settings, |settings, cx| {
        apply_ui_settings(&settings, cx);
        cx.refresh_windows();
    })
    .detach();

    let player = cx.new(|cx| PlayerModel::new(initial.volume, initial.muted, initial.eq, cx));
    player.update(cx, |player, cx| player.set_tracks(initial.playlist, cx));
    persist_player_preferences(&player, &settings, cx);

    actions::bind_keys(cx);
    let window = open_main_window(player.clone(), settings.clone(), cx)?;

    let (commands, command_rx) = async_channel::unbounded();
    let tray = match Tray::new({
        let commands = commands.clone();
        move |action| {
            let _ = commands.send_blocking(AppCommand::Tray(action));
        }
    }) {
        Ok(tray) => Some(Rc::new(RefCell::new(tray))),
        Err(err) => {
            log::warn!("system tray unavailable: {err:#}");
            None
        }
    };
    if let Some(listener) = listener {
        single_instance::listen(listener, move || {
            let _ = commands.send_blocking(AppCommand::Activate);
        });
    }

    cx.spawn({
        let player = player.clone();
        async move |cx| {
            while let Ok(command) = command_rx.recv().await {
                if cx.update(|cx| handle_command(command, window, &player, cx)).is_err() {
                    break;
                }
            }
        }
    })
    .detach();

    if let Some(tray) = tray {
        sync_tray(tray, window, &player, &settings, cx)?;
    }

    cx.on_app_quit({
        let player = player.clone();
        let settings = settings.clone();
        move |cx| {
            settings.update(cx, |settings, _| settings.save_now());
            player.read(cx).shutdown();
            async {}
        }
    })
    .detach();

    cx.activate(true);
    Ok(())
}

fn apply_ui_settings(settings: &Entity<SettingsModel>, cx: &mut App) {
    let ui = &settings.read(cx).get().ui;
    let (theme, lang) = (Theme::new(ui), ui.language);
    cx.set_global(theme);
    cx.set_global(Locale(lang));
}

/// Mirrors playlist, volume and EQ changes into the settings file.
fn persist_player_preferences(player: &Entity<PlayerModel>, settings: &Entity<SettingsModel>, cx: &mut App) {
    let settings = settings.clone();
    cx.subscribe(player, move |player, event, cx| {
        let player = player.read(cx);
        match event {
            PlayerEvent::Playlist => {
                let playlist = player.tracks().to_vec();
                settings.update(cx, |settings, cx| settings.update(cx, |s| s.playlist = playlist));
            }
            PlayerEvent::Preferences => {
                let (volume, muted, eq) = (player.volume(), player.muted(), player.eq());
                settings.update(cx, |settings, cx| {
                    settings.update(cx, |s| {
                        s.volume = volume;
                        s.muted = muted;
                        s.eq = eq;
                    })
                });
            }
            PlayerEvent::State => {}
        }
    })
    .detach();
}

fn open_main_window(
    player: Entity<PlayerModel>,
    settings: Entity<SettingsModel>,
    cx: &mut App,
) -> anyhow::Result<WindowHandle<MainView>> {
    let (width, height) = metrics::FULL_SIZE;
    let options = WindowOptions {
        window_bounds: Some(WindowBounds::Windowed(Bounds::centered(None, size(px(width), px(height)), cx))),
        titlebar: None,
        focus: true,
        show: true,
        kind: WindowKind::Normal,
        is_movable: true,
        is_resizable: false,
        is_minimizable: true,
        window_background: WindowBackgroundAppearance::Transparent,
        window_decorations: Some(WindowDecorations::Client),
        app_id: Some("com.sqhh99.MusicPlayer".into()),
        ..Default::default()
    };
    let dark = cx.global::<Theme>().dark;
    let window = cx.open_window(options, |window, cx| {
        window.set_window_title("MusicPlayer");
        cx.new(|cx| MainView::new(player, settings.clone(), window, cx))
    })?;

    window.update(cx, |view, window, cx| {
        // Closing the last window would quit the app; hide to the tray instead.
        let view_handle = cx.entity().downgrade();
        window.on_window_should_close(cx, move |window, cx| {
            view_handle.update(cx, |view, cx| view.hide_window(window, cx)).ok();
            false
        });
        if let Some(native) = view.native() {
            native.defer(cx, move |native| {
                native.apply_chrome(dark);
                native.install_hooks();
            });
            // Keep the DWM dark-mode hint in sync with the theme.
            cx.observe_global::<Theme>(move |_, cx| {
                let dark = cx.global::<Theme>().dark;
                native.defer(cx, move |native| native.apply_chrome(dark));
            })
            .detach();
        }
    })?;
    Ok(window)
}

fn handle_command(
    command: AppCommand,
    window: WindowHandle<MainView>,
    player: &Entity<PlayerModel>,
    cx: &mut App,
) {
    let player_command = |cx: &mut App, f: fn(&mut PlayerModel, &mut gpui::Context<PlayerModel>)| {
        player.update(cx, f);
    };
    match command {
        AppCommand::Activate | AppCommand::Tray(TrayAction::ShowWindow) => {
            window.update(cx, |view, window, cx| view.show_window(window, cx)).ok();
        }
        AppCommand::Tray(TrayAction::ToggleWindow) => {
            window.update(cx, |view, window, cx| view.toggle_window(window, cx)).ok();
        }
        AppCommand::Tray(TrayAction::TogglePlay) => player_command(cx, PlayerModel::toggle_play),
        AppCommand::Tray(TrayAction::Previous) => player_command(cx, PlayerModel::previous),
        AppCommand::Tray(TrayAction::Next) => player_command(cx, PlayerModel::next),
        AppCommand::Tray(TrayAction::VolumeUp) => player.update(cx, |p, cx| p.adjust_volume(10, cx)),
        AppCommand::Tray(TrayAction::VolumeDown) => player.update(cx, |p, cx| p.adjust_volume(-10, cx)),
        AppCommand::Tray(TrayAction::ToggleMute) => player_command(cx, PlayerModel::toggle_mute),
        AppCommand::Tray(TrayAction::ToggleRepeat) => player_command(cx, PlayerModel::toggle_repeat_one),
        AppCommand::Tray(TrayAction::ToggleShuffle) => player_command(cx, PlayerModel::toggle_shuffle),
        AppCommand::Tray(TrayAction::Quit) => cx.quit(),
    }
}

/// Keeps tray labels, check marks and tooltip in step with the app.
fn sync_tray(
    tray: Rc<RefCell<Tray>>,
    window: WindowHandle<MainView>,
    player: &Entity<PlayerModel>,
    settings: &Entity<SettingsModel>,
    cx: &mut App,
) -> anyhow::Result<()> {
    let refresh: Rc<dyn Fn(&mut App)> = Rc::new({
        let player = player.clone();
        let settings = settings.clone();
        move |cx: &mut App| {
            let window_visible = window.read(cx).map(MainView::is_window_visible).unwrap_or(true);
            let lang = settings.read(cx).get().ui.language;
            let player = player.read(cx);
            tray.borrow_mut().update(TrayState {
                lang,
                window_visible,
                title: player.track().map(|track| track.title.to_string()),
                playing: player.status() == Status::Playing,
                paused: player.status() == Status::Paused,
                muted: player.muted(),
                repeat_one: player.repeat_one(),
                shuffle: player.shuffle(),
            });
        }
    });

    refresh(cx);
    cx.subscribe(player, {
        let refresh = refresh.clone();
        move |_, event, cx| {
            if matches!(event, PlayerEvent::State | PlayerEvent::Preferences) {
                refresh(cx);
            }
        }
    })
    .detach();
    cx.observe(settings, {
        let refresh = refresh.clone();
        move |_, cx| refresh(cx)
    })
    .detach();
    let view = window.entity(cx)?;
    cx.subscribe(&view, move |_, event: &MainViewEvent, cx| match event {
        MainViewEvent::VisibilityChanged => refresh(cx),
    })
    .detach();
    Ok(())
}
