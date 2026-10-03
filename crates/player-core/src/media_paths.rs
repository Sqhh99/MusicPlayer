//! File-system conventions for audio files and their sidecar cover art and lyrics.

use std::path::{Path, PathBuf};

/// Extensions the audio engine can decode, offered in the open-file dialog.
pub const AUDIO_EXTENSIONS: &[&str] = &["mp3", "flac", "wav", "m4a", "aac", "ogg", "oga"];

const COVER_EXTENSIONS: &[&str] = &["jpg", "jpeg", "png", "webp"];

pub fn is_audio_file(path: &Path) -> bool {
    path.extension()
        .and_then(|ext| ext.to_str())
        .is_some_and(|ext| AUDIO_EXTENSIONS.iter().any(|known| known.eq_ignore_ascii_case(ext)))
}

/// `song.jpg` / `song.png` / ... next to `song.mp3`.
pub fn sidecar_cover(audio: &Path) -> Option<PathBuf> {
    COVER_EXTENSIONS.iter().map(|ext| audio.with_extension(ext)).find(|candidate| candidate.is_file())
}

/// `song.lrc` next to `song.mp3`.
pub fn sidecar_lyrics(audio: &Path) -> Option<PathBuf> {
    Some(audio.with_extension("lrc")).filter(|candidate| candidate.is_file())
}

/// File name shown when a track has no title tag.
pub fn display_name(path: &Path) -> String {
    path.file_name()
        .map(|name| name.to_string_lossy().into_owned())
        .unwrap_or_else(|| path.display().to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn recognizes_audio_extensions() {
        assert!(is_audio_file(Path::new("a/b.MP3")));
        assert!(is_audio_file(Path::new("song.flac")));
        assert!(!is_audio_file(Path::new("cover.jpg")));
        assert!(!is_audio_file(Path::new("noext")));
    }

    #[test]
    fn finds_bundled_sidecars() {
        let examples = Path::new(env!("CARGO_MANIFEST_DIR")).join("../../examples");
        let audio = examples.join("Bittersweet Chocolate.m4a");
        assert_eq!(sidecar_cover(&audio), Some(examples.join("Bittersweet Chocolate.jpg")));
        assert_eq!(sidecar_lyrics(&audio), Some(examples.join("Bittersweet Chocolate.lrc")));
        assert_eq!(sidecar_cover(&examples.join("missing.mp3")), None);
        assert_eq!(display_name(&audio), "Bittersweet Chocolate.m4a");
    }
}
