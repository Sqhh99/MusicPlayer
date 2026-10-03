//! Lucide icons bundled under `resources/icons`.

use gpui::SharedString;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Icon {
    ChevronDown,
    FolderOpen,
    ListMusic,
    MicVocal,
    Minus,
    Monitor,
    Music,
    Pause,
    PictureInPicture,
    PictureInPicture2,
    Pill,
    Pin,
    Play,
    Repeat,
    Repeat1,
    Settings,
    Shuffle,
    SkipBack,
    SkipForward,
    SlidersVertical,
    Volume1,
    Volume2,
    VolumeX,
    X,
}

impl Icon {
    pub fn path(self) -> SharedString {
        let name = match self {
            Icon::ChevronDown => "chevron-down",
            Icon::FolderOpen => "folder-open",
            Icon::ListMusic => "list-music",
            Icon::MicVocal => "mic-vocal",
            Icon::Minus => "minus",
            Icon::Monitor => "monitor",
            Icon::Music => "music",
            Icon::Pause => "pause",
            Icon::PictureInPicture => "picture-in-picture",
            Icon::PictureInPicture2 => "picture-in-picture-2",
            Icon::Pill => "pill",
            Icon::Pin => "pin",
            Icon::Play => "play",
            Icon::Repeat => "repeat",
            Icon::Repeat1 => "repeat-1",
            Icon::Settings => "settings",
            Icon::Shuffle => "shuffle",
            Icon::SkipBack => "skip-back",
            Icon::SkipForward => "skip-forward",
            Icon::SlidersVertical => "sliders-vertical",
            Icon::Volume1 => "volume-1",
            Icon::Volume2 => "volume-2",
            Icon::VolumeX => "volume-x",
            Icon::X => "x",
        };
        format!("icons/{name}.svg").into()
    }
}
