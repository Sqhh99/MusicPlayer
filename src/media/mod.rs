//! Track metadata: tags and embedded art via lofty, with sidecar-file fallbacks.
//!
//! Everything here is blocking file I/O and is meant to run on a background executor.

use std::path::Path;
use std::time::Duration;

use lofty::config::ParseOptions;
use lofty::picture::{Picture, PictureType};
use lofty::prelude::*;
use lofty::probe::Probe;
use player_core::lyrics::Lyrics;
use player_core::media_paths;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImageKind {
    Png,
    Jpeg,
    Webp,
    Gif,
    Bmp,
}

impl ImageKind {
    /// Identifies an image by its magic bytes; tag MIME types are often wrong.
    pub fn sniff(bytes: &[u8]) -> Option<Self> {
        match bytes {
            [0x89, b'P', b'N', b'G', ..] => Some(Self::Png),
            [0xFF, 0xD8, 0xFF, ..] => Some(Self::Jpeg),
            [b'R', b'I', b'F', b'F', _, _, _, _, b'W', b'E', b'B', b'P', ..] => Some(Self::Webp),
            [b'G', b'I', b'F', b'8', ..] => Some(Self::Gif),
            [b'B', b'M', ..] => Some(Self::Bmp),
            _ => None,
        }
    }
}

#[derive(Debug, Clone)]
pub struct Cover {
    pub kind: ImageKind,
    pub bytes: Vec<u8>,
}

impl Cover {
    fn from_bytes(bytes: Vec<u8>) -> Option<Self> {
        ImageKind::sniff(&bytes).map(|kind| Self { kind, bytes })
    }
}

#[derive(Debug, Clone, Default)]
pub struct TrackDetails {
    pub title: Option<String>,
    pub artist: Option<String>,
    pub cover: Option<Cover>,
    pub lyrics: Lyrics,
}

/// Reads tags, cover art and lyrics for the track at `path`.
///
/// Cover art prefers the embedded front cover, then any embedded picture, then a sidecar
/// image. Lyrics come from a sidecar `.lrc` file.
pub fn read_details(path: &Path) -> TrackDetails {
    let mut details = TrackDetails::default();

    match Probe::open(path).and_then(|probe| probe.read()) {
        Ok(file) => {
            if let Some(tag) = file.primary_tag().or_else(|| file.first_tag()) {
                details.title = non_empty(tag.title().as_deref());
                details.artist = non_empty(tag.artist().as_deref());
                details.cover = best_picture(tag.pictures())
                    .and_then(|picture| Cover::from_bytes(picture.data().to_vec()));
            }
        }
        Err(err) => log::debug!("no tags for {}: {err}", path.display()),
    }

    if details.cover.is_none() {
        details.cover = media_paths::sidecar_cover(path)
            .and_then(|cover| std::fs::read(cover).ok())
            .and_then(Cover::from_bytes);
    }

    if let Some(lrc) = media_paths::sidecar_lyrics(path) {
        match std::fs::read(&lrc) {
            Ok(bytes) => details.lyrics = Lyrics::from_bytes(&bytes),
            Err(err) => log::warn!("cannot read {}: {err}", lrc.display()),
        }
    }

    details
}

/// Reads only the audio properties to get a track's duration (no cover art decoding).
pub fn probe_duration(path: &Path) -> Option<Duration> {
    let options = ParseOptions::new().read_cover_art(false).read_tags(false);
    let file = Probe::open(path).ok()?.options(options).read().ok()?;
    Some(file.properties().duration()).filter(|duration| !duration.is_zero())
}

fn best_picture(pictures: &[Picture]) -> Option<&Picture> {
    pictures.iter().find(|picture| picture.pic_type() == PictureType::CoverFront).or_else(|| pictures.first())
}

fn non_empty(value: Option<&str>) -> Option<String> {
    value.map(str::trim).filter(|value| !value.is_empty()).map(str::to_string)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn sniffs_image_formats() {
        assert_eq!(ImageKind::sniff(&[0x89, b'P', b'N', b'G', 0x0D]), Some(ImageKind::Png));
        assert_eq!(ImageKind::sniff(&[0xFF, 0xD8, 0xFF, 0xE0]), Some(ImageKind::Jpeg));
        assert_eq!(ImageKind::sniff(b"RIFF\0\0\0\0WEBPVP8 "), Some(ImageKind::Webp));
        assert_eq!(ImageKind::sniff(b"not an image"), None);
    }

    #[test]
    fn reads_sidecars_and_duration() {
        let dir = std::env::temp_dir().join(format!("music-player-media-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let audio = dir.join("song.wav");
        // One second of 8 kHz mono silence.
        let mut wav = Vec::new();
        let data_len = 8000u32 * 2;
        wav.extend(b"RIFF");
        wav.extend((36 + data_len).to_le_bytes());
        wav.extend(b"WAVEfmt ");
        wav.extend(16u32.to_le_bytes());
        wav.extend(1u16.to_le_bytes());
        wav.extend(1u16.to_le_bytes());
        wav.extend(8000u32.to_le_bytes());
        wav.extend(16000u32.to_le_bytes());
        wav.extend(2u16.to_le_bytes());
        wav.extend(16u16.to_le_bytes());
        wav.extend(b"data");
        wav.extend(data_len.to_le_bytes());
        wav.resize(wav.len() + data_len as usize, 0);
        std::fs::write(&audio, wav).unwrap();
        std::fs::write(dir.join("song.lrc"), "[00:00.50]hello").unwrap();
        let examples = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("examples");
        std::fs::copy(examples.join("Bittersweet Chocolate.jpg"), dir.join("song.jpg")).unwrap();

        let duration = probe_duration(&audio).unwrap();
        assert!((duration.as_millis() as i64 - 1000).abs() <= 10, "{duration:?}");

        let details = read_details(&audio);
        assert_eq!(details.title, None);
        assert_eq!(details.lyrics.lines.len(), 1);
        assert_eq!(details.cover.map(|cover| cover.kind), Some(ImageKind::Jpeg));
        std::fs::remove_dir_all(dir).unwrap();
    }
}
