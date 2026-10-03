//! Application state shared between views, tray and persistence.

pub mod player;
pub mod settings;

pub use player::{PlayerEvent, PlayerModel, Status};
pub use settings::SettingsModel;
