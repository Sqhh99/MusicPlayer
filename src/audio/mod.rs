//! Audio playback: a dedicated thread owns the output device and decoders; the UI talks
//! to it through [`AudioHandle`] commands and receives [`AudioEvent`]s back.

mod engine;
mod eq_source;

use std::path::PathBuf;
use std::sync::Arc;
use std::time::Duration;

pub use eq_source::EqParams;

/// Identifies one load request so stale events from a previous track can be ignored.
pub type LoadId = u64;

#[derive(Debug)]
pub enum AudioCommand {
    Load { path: PathBuf, id: LoadId, autoplay: bool },
    Play,
    Pause,
    Stop,
    Seek(Duration),
    SetVolume(f32),
    Shutdown,
}

#[derive(Debug, Clone)]
pub enum AudioEvent {
    Loaded {
        id: LoadId,
        duration: Option<Duration>,
    },
    LoadFailed {
        id: LoadId,
    },
    Position {
        id: LoadId,
        position: Duration,
    },
    Playing {
        id: LoadId,
        playing: bool,
    },
    TrackEnded {
        id: LoadId,
    },
    /// The output device could not be opened; playback is unavailable.
    DeviceError(String),
}

/// Cheap, cloneable handle to the audio thread.
#[derive(Clone)]
pub struct AudioHandle {
    commands: crossbeam_channel::Sender<AudioCommand>,
    eq: Arc<EqParams>,
}

impl AudioHandle {
    /// Starts the audio thread. Events are delivered on the returned receiver.
    pub fn spawn(eq_gains_db: [f32; 3]) -> (Self, async_channel::Receiver<AudioEvent>) {
        let (commands, command_rx) = crossbeam_channel::unbounded();
        let (event_tx, events) = async_channel::unbounded();
        let eq = Arc::new(EqParams::new(eq_gains_db));
        engine::spawn(command_rx, event_tx, eq.clone());
        (Self { commands, eq }, events)
    }

    pub fn send(&self, command: AudioCommand) {
        // The engine only goes away at shutdown; dropping late commands is fine then.
        let _ = self.commands.send(command);
    }

    /// Updates EQ gains; takes effect within a few milliseconds without a command round-trip.
    pub fn set_eq(&self, gains_db: [f32; 3]) {
        self.eq.set(gains_db);
    }
}
