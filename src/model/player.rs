//! `PlayerModel`: the single source of truth for playback state, shared by every view.

use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::Duration;

use gpui::{Context, EventEmitter, Image, ImageFormat, SharedString, Task};
use player_core::eq::{Band, EqLevels};
use player_core::lyrics::Lyrics;
use player_core::media_paths;
use player_core::queue::{PlayQueue, Previous, TrackEnd};

use crate::audio::{AudioCommand, AudioEvent, AudioHandle, LoadId};
use crate::media::{self, Cover, ImageKind};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Status {
    Stopped,
    Playing,
    Paused,
}

/// Emitted for changes other parts of the app persist or mirror (settings, tray).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum PlayerEvent {
    Playlist,
    Preferences,
    State,
}

/// Display information for the current track.
#[derive(Clone)]
pub struct TrackInfo {
    pub path: PathBuf,
    pub title: SharedString,
    pub artist: Option<SharedString>,
    pub cover: Option<Arc<Image>>,
}

const DURATION_PROBE_BATCH: usize = 8;

pub struct PlayerModel {
    audio: AudioHandle,
    queue: PlayQueue,
    rng: fastrand::Rng,
    load_id: LoadId,
    /// Whether the engine currently holds the queue's current track.
    loaded: bool,
    status: Status,
    position: Duration,
    duration: Duration,
    volume: u8,
    muted: bool,
    eq: EqLevels,
    track: Option<TrackInfo>,
    lyrics: Arc<Lyrics>,
    lyric_index: Option<usize>,
    durations: Vec<Option<Duration>>,
    consecutive_failures: usize,
    _audio_events: Task<()>,
    details_task: Option<Task<()>>,
    probe_task: Option<Task<()>>,
}

impl EventEmitter<PlayerEvent> for PlayerModel {}

impl PlayerModel {
    pub fn new(volume: u8, muted: bool, eq: EqLevels, cx: &mut Context<Self>) -> Self {
        let (audio, events) = AudioHandle::spawn(eq.gains_db());
        let audio_events = cx.spawn(async move |this, cx| {
            while let Ok(event) = events.recv().await {
                if this.update(cx, |model, cx| model.on_audio_event(event, cx)).is_err() {
                    break;
                }
            }
        });
        let model = Self {
            audio,
            queue: PlayQueue::new(),
            rng: fastrand::Rng::new(),
            load_id: 0,
            loaded: false,
            status: Status::Stopped,
            position: Duration::ZERO,
            duration: Duration::ZERO,
            volume: volume.min(100),
            muted,
            eq,
            track: None,
            lyrics: Arc::default(),
            lyric_index: None,
            durations: Vec::new(),
            consecutive_failures: 0,
            _audio_events: audio_events,
            details_task: None,
            probe_task: None,
        };
        model.apply_volume();
        model
    }

    // ── Read access ─────────────────────────────────────────────────────────

    pub fn status(&self) -> Status {
        self.status
    }

    pub fn is_playing(&self) -> bool {
        self.status == Status::Playing
    }

    pub fn position(&self) -> Duration {
        self.position
    }

    pub fn duration(&self) -> Duration {
        self.duration
    }

    pub fn volume(&self) -> u8 {
        self.volume
    }

    pub fn muted(&self) -> bool {
        self.muted
    }

    pub fn eq(&self) -> EqLevels {
        self.eq
    }

    pub fn repeat_one(&self) -> bool {
        self.queue.repeat_one()
    }

    pub fn shuffle(&self) -> bool {
        self.queue.shuffle()
    }

    pub fn track(&self) -> Option<&TrackInfo> {
        self.track.as_ref()
    }

    pub fn tracks(&self) -> &[PathBuf] {
        self.queue.tracks()
    }

    pub fn current_index(&self) -> Option<usize> {
        self.queue.current()
    }

    pub fn track_duration(&self, index: usize) -> Option<Duration> {
        self.durations.get(index).copied().flatten()
    }

    pub fn lyrics(&self) -> &Arc<Lyrics> {
        &self.lyrics
    }

    pub fn lyric_index(&self) -> Option<usize> {
        self.lyric_index
    }

    // ── Commands ────────────────────────────────────────────────────────────

    /// Replaces the playlist. Playback stops; the first track is shown but not started.
    pub fn set_tracks(&mut self, tracks: Vec<PathBuf>, cx: &mut Context<Self>) {
        self.audio.send(AudioCommand::Stop);
        self.queue.set_tracks(tracks);
        self.loaded = false;
        self.status = Status::Stopped;
        self.position = Duration::ZERO;
        self.durations = vec![None; self.queue.len()];
        self.duration = Duration::ZERO;
        self.consecutive_failures = 0;
        self.refresh_track(cx);
        self.start_duration_probe(cx);
        cx.emit(PlayerEvent::Playlist);
        self.changed(cx);
    }

    pub fn play_index(&mut self, index: usize, cx: &mut Context<Self>) {
        if self.queue.select(index) {
            self.consecutive_failures = 0;
            self.load_current(true, cx);
        }
    }

    pub fn toggle_play(&mut self, cx: &mut Context<Self>) {
        match self.status {
            Status::Playing => self.audio.send(AudioCommand::Pause),
            Status::Paused if self.loaded => self.audio.send(AudioCommand::Play),
            _ if self.queue.current().is_some() => self.load_current(true, cx),
            _ => {}
        }
    }

    pub fn next(&mut self, cx: &mut Context<Self>) {
        if self.queue.next(&mut self.rng).is_some() {
            self.consecutive_failures = 0;
            self.load_current(true, cx);
        }
    }

    pub fn previous(&mut self, cx: &mut Context<Self>) {
        match self.queue.previous() {
            Some(Previous::Play(_)) => {
                self.consecutive_failures = 0;
                self.load_current(true, cx);
            }
            Some(Previous::Restart) if self.loaded => {
                self.seek(Duration::ZERO, cx);
                self.audio.send(AudioCommand::Play);
            }
            Some(Previous::Restart) => self.load_current(true, cx),
            None => {}
        }
    }

    pub fn seek(&mut self, position: Duration, cx: &mut Context<Self>) {
        if !self.loaded {
            return;
        }
        let position = if self.duration.is_zero() { position } else { position.min(self.duration) };
        self.audio.send(AudioCommand::Seek(position));
        self.set_position(position, cx);
    }

    pub fn set_volume(&mut self, volume: u8, cx: &mut Context<Self>) {
        let volume = volume.min(100);
        if volume == self.volume {
            return;
        }
        self.volume = volume;
        self.apply_volume();
        cx.emit(PlayerEvent::Preferences);
        self.changed(cx);
    }

    pub fn adjust_volume(&mut self, delta: i16, cx: &mut Context<Self>) {
        let volume = (self.volume as i16 + delta).clamp(0, 100) as u8;
        self.set_volume(volume, cx);
    }

    pub fn toggle_mute(&mut self, cx: &mut Context<Self>) {
        self.muted = !self.muted;
        self.apply_volume();
        cx.emit(PlayerEvent::Preferences);
        self.changed(cx);
    }

    pub fn toggle_repeat_one(&mut self, cx: &mut Context<Self>) {
        self.queue.set_repeat_one(!self.queue.repeat_one());
        self.changed(cx);
    }

    pub fn toggle_shuffle(&mut self, cx: &mut Context<Self>) {
        self.queue.set_shuffle(!self.queue.shuffle());
        self.changed(cx);
    }

    pub fn set_eq_level(&mut self, band: Band, level: u8, cx: &mut Context<Self>) {
        if self.eq.get(band) == level {
            return;
        }
        self.eq.set(band, level);
        self.audio.set_eq(self.eq.gains_db());
        cx.emit(PlayerEvent::Preferences);
        cx.notify();
    }

    /// Stops the audio thread; called when the app quits.
    pub fn shutdown(&self) {
        self.audio.send(AudioCommand::Shutdown);
    }

    // ── Internals ───────────────────────────────────────────────────────────

    fn changed(&mut self, cx: &mut Context<Self>) {
        cx.emit(PlayerEvent::State);
        cx.notify();
    }

    fn apply_volume(&self) {
        let volume = if self.muted { 0.0 } else { self.volume as f32 / 100.0 };
        self.audio.send(AudioCommand::SetVolume(volume));
    }

    fn load_current(&mut self, autoplay: bool, cx: &mut Context<Self>) {
        let Some(path) = self.queue.current_path().map(Path::to_path_buf) else {
            return;
        };
        self.load_id += 1;
        self.audio.send(AudioCommand::Load { path, id: self.load_id, autoplay });
        self.loaded = true;
        self.status = if autoplay { Status::Playing } else { Status::Paused };
        self.duration = self.queue.current().and_then(|i| self.track_duration(i)).unwrap_or_default();
        self.set_position(Duration::ZERO, cx);
        self.refresh_track(cx);
        self.changed(cx);
    }

    fn set_position(&mut self, position: Duration, cx: &mut Context<Self>) {
        self.position = position;
        self.lyric_index = self.lyrics.index_at(position.as_millis() as u64);
        cx.notify();
    }

    /// Updates track info for the queue's current track, loading tags in the background.
    fn refresh_track(&mut self, cx: &mut Context<Self>) {
        let Some(path) = self.queue.current_path().map(Path::to_path_buf) else {
            self.track = None;
            self.lyrics = Arc::default();
            self.lyric_index = None;
            self.details_task = None;
            return;
        };
        if self.track.as_ref().is_some_and(|track| track.path == path) {
            return;
        }

        self.track = Some(TrackInfo {
            title: media_paths::display_name(&path).into(),
            artist: None,
            cover: None,
            path: path.clone(),
        });
        self.lyrics = Arc::default();
        self.lyric_index = None;

        self.details_task = Some(cx.spawn(async move |this, cx| {
            let lookup = path.clone();
            let details = cx.background_executor().spawn(async move { media::read_details(&lookup) }).await;
            this.update(cx, |model, cx| {
                let Some(track) = model.track.as_mut().filter(|track| track.path == path) else {
                    return;
                };
                if let Some(title) = details.title {
                    track.title = title.into();
                }
                track.artist = details.artist.map(Into::into);
                track.cover = details.cover.map(to_gpui_image);
                model.lyrics = Arc::new(details.lyrics);
                model.lyric_index = model.lyrics.index_at(model.position.as_millis() as u64);
                model.changed(cx);
            })
            .ok();
        }));
    }

    fn start_duration_probe(&mut self, cx: &mut Context<Self>) {
        let tracks = self.queue.tracks().to_vec();
        self.probe_task = Some(cx.spawn(async move |this, cx| {
            for (batch_index, batch) in tracks.chunks(DURATION_PROBE_BATCH).enumerate() {
                let batch = batch.to_vec();
                let durations =
                    cx.background_executor()
                        .spawn(async move {
                            batch.iter().map(|path| media::probe_duration(path)).collect::<Vec<_>>()
                        })
                        .await;
                let start = batch_index * DURATION_PROBE_BATCH;
                let updated = this.update(cx, |model, cx| {
                    for (offset, duration) in durations.into_iter().enumerate() {
                        if let Some(slot) = model.durations.get_mut(start + offset) {
                            *slot = duration;
                        }
                    }
                    if model.duration.is_zero()
                        && let Some(duration) = model.current_index().and_then(|i| model.track_duration(i))
                    {
                        model.duration = duration;
                    }
                    cx.notify();
                });
                if updated.is_err() {
                    break;
                }
            }
        }));
    }

    fn on_audio_event(&mut self, event: AudioEvent, cx: &mut Context<Self>) {
        match event {
            AudioEvent::Loaded { id, duration } if id == self.load_id => {
                self.consecutive_failures = 0;
                if let Some(duration) = duration.filter(|d| !d.is_zero()) {
                    self.duration = duration;
                    if let Some(slot) = self.queue.current().and_then(|i| self.durations.get_mut(i)) {
                        *slot = Some(duration);
                    }
                }
                cx.notify();
            }
            AudioEvent::LoadFailed { id } if id == self.load_id => {
                self.loaded = false;
                self.consecutive_failures += 1;
                if self.consecutive_failures < self.queue.len() && self.queue.next(&mut self.rng).is_some() {
                    self.load_current(true, cx);
                } else {
                    self.consecutive_failures = 0;
                    self.status = Status::Stopped;
                    self.changed(cx);
                }
            }
            AudioEvent::Position { id, position } if id == self.load_id => {
                self.set_position(position, cx);
            }
            AudioEvent::Playing { id, playing } if id == self.load_id => {
                let status = if playing { Status::Playing } else { Status::Paused };
                if status != self.status {
                    self.status = status;
                    self.changed(cx);
                }
            }
            AudioEvent::TrackEnded { id } if id == self.load_id => {
                match self.queue.on_track_end(&mut self.rng) {
                    Some(TrackEnd::Repeat | TrackEnd::Play(_)) => self.load_current(true, cx),
                    None => {
                        self.loaded = false;
                        self.status = Status::Stopped;
                        self.changed(cx);
                    }
                }
            }
            AudioEvent::DeviceError(error) => {
                log::error!("audio device unavailable: {error}");
                self.loaded = false;
                self.status = Status::Stopped;
                self.changed(cx);
            }
            // Events from a superseded load.
            _ => {}
        }
    }
}

fn to_gpui_image(cover: Cover) -> Arc<Image> {
    let format = match cover.kind {
        ImageKind::Png => ImageFormat::Png,
        ImageKind::Jpeg => ImageFormat::Jpeg,
        ImageKind::Webp => ImageFormat::Webp,
        ImageKind::Gif => ImageFormat::Gif,
        ImageKind::Bmp => ImageFormat::Bmp,
    };
    Arc::new(Image::from_bytes(format, cover.bytes))
}
