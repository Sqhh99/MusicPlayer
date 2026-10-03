//! The audio thread: owns the output device and the per-track rodio player.

use std::fs::File;
use std::sync::Arc;
use std::time::Duration;

use crossbeam_channel::{Receiver, RecvTimeoutError};
use rodio::{Decoder, DeviceSinkBuilder, MixerDeviceSink, Player, Source};

use super::eq_source::{EqParams, EqSource};
use super::{AudioCommand, AudioEvent, LoadId};

const TICK: Duration = Duration::from_millis(50);
/// Position updates are sent every N ticks while playing.
const POSITION_EVERY_TICKS: u32 = 3;

pub(super) fn spawn(
    commands: Receiver<AudioCommand>,
    events: async_channel::Sender<AudioEvent>,
    eq: Arc<EqParams>,
) {
    std::thread::Builder::new()
        .name("audio-engine".into())
        .spawn(move || Engine::new(events, eq).run(commands))
        .expect("failed to spawn audio thread");
}

struct Track {
    id: LoadId,
    player: Player,
    ended: bool,
}

struct Engine {
    events: async_channel::Sender<AudioEvent>,
    eq: Arc<EqParams>,
    sink: Option<MixerDeviceSink>,
    track: Option<Track>,
    volume: f32,
}

impl Engine {
    fn new(events: async_channel::Sender<AudioEvent>, eq: Arc<EqParams>) -> Self {
        Self { events, eq, sink: None, track: None, volume: 0.8 }
    }

    fn run(mut self, commands: Receiver<AudioCommand>) {
        let mut ticks = 0u32;
        loop {
            match commands.recv_timeout(TICK) {
                Ok(AudioCommand::Shutdown) | Err(RecvTimeoutError::Disconnected) => break,
                Ok(command) => self.handle(command),
                Err(RecvTimeoutError::Timeout) => {}
            }
            ticks = ticks.wrapping_add(1);
            self.poll(ticks.is_multiple_of(POSITION_EVERY_TICKS));
        }
        self.track = None;
    }

    fn emit(&self, event: AudioEvent) {
        let _ = self.events.send_blocking(event);
    }

    /// Opens the output device on first use so startup never blocks on audio drivers.
    fn sink(&mut self) -> Option<&MixerDeviceSink> {
        if self.sink.is_none() {
            match DeviceSinkBuilder::open_default_sink() {
                Ok(mut sink) => {
                    sink.log_on_drop(false);
                    self.sink = Some(sink);
                }
                Err(err) => {
                    log::error!("cannot open audio output: {err}");
                    self.emit(AudioEvent::DeviceError(err.to_string()));
                }
            }
        }
        self.sink.as_ref()
    }

    fn handle(&mut self, command: AudioCommand) {
        match command {
            AudioCommand::Load { path, id, autoplay } => {
                // Drop the previous player first so its device stream stops immediately.
                self.track = None;
                match self.load(&path, autoplay) {
                    Ok((player, duration)) => {
                        self.track = Some(Track { id, player, ended: false });
                        self.emit(AudioEvent::Loaded { id, duration });
                        self.emit(AudioEvent::Playing { id, playing: autoplay });
                    }
                    Err(error) => {
                        log::warn!("cannot play {}: {error}", path.display());
                        self.emit(AudioEvent::LoadFailed { id });
                    }
                }
            }
            AudioCommand::Play => self.set_playing(true),
            AudioCommand::Pause => self.set_playing(false),
            AudioCommand::Stop => {
                if let Some(track) = self.track.take() {
                    self.emit(AudioEvent::Playing { id: track.id, playing: false });
                }
            }
            AudioCommand::Seek(position) => {
                if let Some(track) = &mut self.track {
                    if let Err(err) = track.player.try_seek(position) {
                        log::warn!("seek failed: {err}");
                    }
                    track.ended = false;
                    let event = AudioEvent::Position { id: track.id, position: track.player.get_pos() };
                    self.emit(event);
                }
            }
            AudioCommand::SetVolume(volume) => {
                self.volume = volume.clamp(0.0, 1.0);
                if let Some(track) = &self.track {
                    track.player.set_volume(self.volume);
                }
            }
            AudioCommand::Shutdown => {}
        }
    }

    fn load(&mut self, path: &std::path::Path, autoplay: bool) -> Result<(Player, Option<Duration>), String> {
        let file = File::open(path).map_err(|err| err.to_string())?;
        let decoder = Decoder::try_from(file).map_err(|err| err.to_string())?;
        let duration = decoder.total_duration();
        let source = EqSource::new(decoder, self.eq.clone());
        let volume = self.volume;
        let sink = self.sink().ok_or_else(|| "no audio output device".to_string())?;
        let player = Player::connect_new(sink.mixer());
        player.set_volume(volume);
        if !autoplay {
            player.pause();
        }
        player.append(source);
        Ok((player, duration))
    }

    fn set_playing(&mut self, playing: bool) {
        // A finished player has no source left; the model reloads the track instead.
        let Some(track) = self.track.as_ref().filter(|track| !track.ended) else { return };
        if playing {
            track.player.play();
        } else {
            track.player.pause();
        }
        let id = track.id;
        self.emit(AudioEvent::Playing { id, playing });
    }

    fn poll(&mut self, report_position: bool) {
        let Some(track) = &mut self.track else { return };
        if track.ended || track.player.is_paused() {
            return;
        }
        if track.player.empty() {
            track.ended = true;
            let id = track.id;
            self.emit(AudioEvent::TrackEnded { id });
        } else if report_position {
            let event = AudioEvent::Position { id: track.id, position: track.player.get_pos() };
            self.emit(event);
        }
    }
}
