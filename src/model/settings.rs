//! `SettingsModel`: user preferences, persisted to disk shortly after each change.

use std::path::PathBuf;
use std::time::Duration;

use gpui::{Context, Task};
use player_core::settings::Settings;

const SAVE_DELAY: Duration = Duration::from_millis(400);

pub struct SettingsModel {
    settings: Settings,
    path: Option<PathBuf>,
    save_task: Option<Task<()>>,
}

impl SettingsModel {
    /// Loads settings from the per-user config directory, falling back to defaults.
    pub fn load() -> Self {
        let path = directories::ProjectDirs::from("com", "sqhh99", "MusicPlayer")
            .map(|dirs| dirs.config_dir().join("settings.json"));
        let mut settings = match path.as_deref().map(Settings::load) {
            Some(Ok(settings)) => settings,
            Some(Err(err)) => {
                log::warn!("ignoring unreadable settings: {err}");
                Settings::default()
            }
            None => Settings::default(),
        };
        settings.playlist.retain(|track| track.is_file());
        if let Some(path) = &path {
            log::info!("settings file: {}", path.display());
        }
        Self { settings, path, save_task: None }
    }

    pub fn get(&self) -> &Settings {
        &self.settings
    }

    /// Applies a change, notifies observers and schedules a save.
    pub fn update(&mut self, cx: &mut Context<Self>, change: impl FnOnce(&mut Settings)) {
        let before = self.settings.clone();
        change(&mut self.settings);
        self.settings = std::mem::take(&mut self.settings).sanitized();
        if self.settings == before {
            return;
        }
        cx.notify();
        self.save_task = Some(cx.spawn(async move |this, cx| {
            cx.background_executor().timer(SAVE_DELAY).await;
            this.update(cx, |model, _| model.save_now()).ok();
        }));
    }

    pub fn save_now(&mut self) {
        self.save_task = None;
        if let Some(path) = &self.path
            && let Err(err) = self.settings.save(path)
        {
            log::error!("cannot save settings to {}: {err}", path.display());
        }
    }
}
