//! Persistent user settings, stored as JSON.

use std::fs;
use std::io;
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};

use crate::eq::EqLevels;
use crate::i18n::Lang;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ThemeMode {
    #[default]
    Day,
    Night,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default)]
pub struct UiSettings {
    pub theme: ThemeMode,
    /// Opacity of the window surface, 0..=100.
    pub material_strength: u8,
    /// Opacity of button backgrounds, 0..=100.
    pub button_material_strength: u8,
    pub background_glow: bool,
    pub language: Lang,
}

impl Default for UiSettings {
    fn default() -> Self {
        Self {
            theme: ThemeMode::Day,
            material_strength: 72,
            button_material_strength: 62,
            background_glow: true,
            language: Lang::Zh,
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(default)]
pub struct Settings {
    pub playlist: Vec<PathBuf>,
    /// Folder the open-file dialog starts in.
    pub last_dir: Option<PathBuf>,
    pub volume: u8,
    pub muted: bool,
    pub eq: EqLevels,
    pub ui: UiSettings,
}

impl Default for Settings {
    fn default() -> Self {
        Self {
            playlist: Vec::new(),
            last_dir: None,
            volume: 80,
            muted: false,
            eq: EqLevels::default(),
            ui: UiSettings::default(),
        }
    }
}

impl Settings {
    /// Reads settings from `path`. A missing file yields the defaults.
    pub fn load(path: &Path) -> io::Result<Self> {
        match fs::read(path) {
            Ok(bytes) => {
                Ok(serde_json::from_slice::<Settings>(&bytes).map_err(io::Error::other)?.sanitized())
            }
            Err(err) if err.kind() == io::ErrorKind::NotFound => Ok(Self::default()),
            Err(err) => Err(err),
        }
    }

    /// Writes settings atomically (temp file + rename), creating the directory if needed.
    pub fn save(&self, path: &Path) -> io::Result<()> {
        if let Some(dir) = path.parent() {
            fs::create_dir_all(dir)?;
        }
        let json = serde_json::to_vec_pretty(self).map_err(io::Error::other)?;
        let tmp = path.with_extension("json.tmp");
        fs::write(&tmp, json)?;
        fs::rename(&tmp, path)
    }

    pub fn sanitized(mut self) -> Self {
        self.volume = self.volume.min(100);
        self.eq = self.eq.clamped();
        self.ui.material_strength = self.ui.material_strength.min(100);
        self.ui.button_material_strength = self.ui.button_material_strength.min(100);
        self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_match_original_app() {
        let s = Settings::default();
        assert_eq!(s.volume, 80);
        assert_eq!(s.eq, EqLevels { bass: 50, mid: 50, treble: 50 });
        assert_eq!(s.ui.material_strength, 72);
        assert_eq!(s.ui.button_material_strength, 62);
        assert!(s.ui.background_glow);
        assert_eq!(s.ui.theme, ThemeMode::Day);
        assert_eq!(s.ui.language, Lang::Zh);
    }

    #[test]
    fn missing_and_unknown_fields_and_clamping() {
        let json = r#"{"volume":250,"ui":{"theme":"night","language":"en","future":1},"extra":true}"#;
        let s: Settings = serde_json::from_str::<Settings>(json).unwrap().sanitized();
        assert_eq!(s.volume, 100);
        assert_eq!(s.ui.theme, ThemeMode::Night);
        assert_eq!(s.ui.language, Lang::En);
        assert_eq!(s.ui.material_strength, 72);
        assert_eq!(s.eq, EqLevels::default());
    }

    #[test]
    fn save_and_load_round_trip() {
        let dir = std::env::temp_dir().join(format!("player-core-test-{}", std::process::id()));
        let path = dir.join("settings.json");
        assert_eq!(Settings::load(&path).unwrap(), Settings::default());

        let mut s = Settings {
            playlist: vec![PathBuf::from("a.mp3"), PathBuf::from("目录/b.flac")],
            last_dir: Some(PathBuf::from("目录")),
            muted: true,
            ..Default::default()
        };
        s.eq.bass = 90;
        s.ui.background_glow = false;
        s.save(&path).unwrap();
        assert_eq!(Settings::load(&path).unwrap(), s);

        fs::write(&path, b"{not json").unwrap();
        assert!(Settings::load(&path).is_err());
        fs::remove_dir_all(dir).unwrap();
    }
}
