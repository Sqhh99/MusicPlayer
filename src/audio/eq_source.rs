//! A rodio [`Source`] adapter that runs samples through the three-band equalizer.

use std::sync::Arc;
use std::sync::atomic::{AtomicU32, AtomicU64, Ordering};
use std::time::Duration;

use player_core::eq::Equalizer;
use rodio::source::SeekError;
use rodio::{ChannelCount, Sample, SampleRate, Source};

/// EQ gains shared between the UI and the audio thread without locking.
#[derive(Debug, Default)]
pub struct EqParams {
    gains_db: [AtomicU32; 3],
    version: AtomicU64,
}

impl EqParams {
    pub fn new(gains_db: [f32; 3]) -> Self {
        let params = Self::default();
        params.set(gains_db);
        params
    }

    pub fn set(&self, gains_db: [f32; 3]) {
        for (slot, gain) in self.gains_db.iter().zip(gains_db) {
            slot.store(gain.to_bits(), Ordering::Relaxed);
        }
        self.version.fetch_add(1, Ordering::Release);
    }

    fn snapshot(&self) -> (u64, [f32; 3]) {
        let version = self.version.load(Ordering::Acquire);
        let gains = [0, 1, 2].map(|i| f32::from_bits(self.gains_db[i].load(Ordering::Relaxed)));
        (version, gains)
    }
}

/// How many frames pass between checks for new gains or a format change.
const REFRESH_FRAMES: u32 = 512;

pub struct EqSource<S> {
    inner: S,
    params: Arc<EqParams>,
    eq: Equalizer,
    version: u64,
    sample_rate: SampleRate,
    channels: ChannelCount,
    channel: usize,
    frames_until_refresh: u32,
}

impl<S: Source> EqSource<S> {
    pub fn new(inner: S, params: Arc<EqParams>) -> Self {
        let (version, gains) = params.snapshot();
        let (sample_rate, channels) = (inner.sample_rate(), inner.channels());
        Self {
            eq: Equalizer::new(sample_rate.get(), channels.get(), gains),
            inner,
            params,
            version,
            sample_rate,
            channels,
            channel: 0,
            frames_until_refresh: REFRESH_FRAMES,
        }
    }

    /// Picks up new gains or a changed stream format; only called on frame boundaries.
    fn refresh(&mut self) {
        let (sample_rate, channels) = (self.inner.sample_rate(), self.inner.channels());
        if channels != self.channels {
            self.channels = channels;
            self.eq.set_channels(channels.get());
        }
        let (version, gains) = self.params.snapshot();
        if version != self.version || sample_rate != self.sample_rate {
            self.version = version;
            self.sample_rate = sample_rate;
            self.eq.configure(sample_rate.get(), gains);
        }
    }
}

impl<S: Source> Iterator for EqSource<S> {
    type Item = Sample;

    fn next(&mut self) -> Option<Sample> {
        if self.channel == 0 {
            self.frames_until_refresh -= 1;
            if self.frames_until_refresh == 0 {
                self.frames_until_refresh = REFRESH_FRAMES;
                self.refresh();
            }
        }
        let sample = self.inner.next()?;
        let out = self.eq.process(self.channel, sample);
        self.channel += 1;
        if self.channel >= self.channels.get() as usize {
            self.channel = 0;
        }
        Some(out)
    }

    fn size_hint(&self) -> (usize, Option<usize>) {
        self.inner.size_hint()
    }
}

impl<S: Source> Source for EqSource<S> {
    fn current_span_len(&self) -> Option<usize> {
        self.inner.current_span_len()
    }

    fn channels(&self) -> ChannelCount {
        self.inner.channels()
    }

    fn sample_rate(&self) -> SampleRate {
        self.inner.sample_rate()
    }

    fn total_duration(&self) -> Option<Duration> {
        self.inner.total_duration()
    }

    fn try_seek(&mut self, pos: Duration) -> Result<(), SeekError> {
        self.inner.try_seek(pos)?;
        // Old filter memory would otherwise ring into the new position.
        self.eq.reset();
        self.channel = 0;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use std::fs::File;
    use std::path::PathBuf;

    use rodio::Decoder;

    use super::*;

    /// Writes a 16-bit stereo sine WAV and returns its path.
    fn sine_wav(name: &str, freq: f32, seconds: f32) -> PathBuf {
        let rate = 44_100u32;
        let frames = (rate as f32 * seconds) as u32;
        let mut pcm = Vec::with_capacity(frames as usize * 4);
        for i in 0..frames {
            let v = ((2.0 * std::f32::consts::PI * freq * i as f32 / rate as f32).sin() * 8000.0) as i16;
            pcm.extend(v.to_le_bytes());
            pcm.extend(v.to_le_bytes());
        }
        let mut wav = Vec::new();
        wav.extend(b"RIFF");
        wav.extend((36 + pcm.len() as u32).to_le_bytes());
        wav.extend(b"WAVEfmt ");
        wav.extend(16u32.to_le_bytes());
        wav.extend(1u16.to_le_bytes()); // PCM
        wav.extend(2u16.to_le_bytes()); // channels
        wav.extend(rate.to_le_bytes());
        wav.extend((rate * 4).to_le_bytes());
        wav.extend(4u16.to_le_bytes());
        wav.extend(16u16.to_le_bytes());
        wav.extend(b"data");
        wav.extend((pcm.len() as u32).to_le_bytes());
        wav.extend(pcm);

        let dir = std::env::temp_dir().join(format!("music-player-tests-{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let path = dir.join(name);
        std::fs::write(&path, wav).unwrap();
        path
    }

    fn decode(path: &PathBuf) -> Decoder<std::io::BufReader<File>> {
        Decoder::try_from(File::open(path).unwrap()).unwrap()
    }

    fn peak(samples: impl Iterator<Item = f32>) -> f32 {
        samples.fold(0.0f32, |peak, s| peak.max(s.abs()))
    }

    #[test]
    fn flat_eq_is_transparent() {
        let path = sine_wav("flat.wav", 440.0, 0.2);
        let raw: Vec<f32> = decode(&path).collect();
        let eq: Vec<f32> = EqSource::new(decode(&path), Arc::new(EqParams::new([0.0; 3]))).collect();
        assert_eq!(raw, eq);
    }

    #[test]
    fn bass_boost_and_cut_change_low_tones() {
        let path = sine_wav("low.wav", 60.0, 0.5);
        let reference = peak(decode(&path).skip(8820));
        let cut = peak(EqSource::new(decode(&path), Arc::new(EqParams::new([-12.0, 0.0, 0.0]))).skip(8820));
        // -12 dB is a quarter of the amplitude; allow for the shelf's transition band.
        assert!(cut < reference * 0.35, "cut {cut} vs {reference}");

        let boost = peak(EqSource::new(decode(&path), Arc::new(EqParams::new([6.0, 0.0, 0.0]))).skip(8820));
        // The boost is offset by an equal preamp cut, so the low tone keeps its level
        // while everything else would be attenuated.
        assert!((boost - reference).abs() < reference * 0.15, "boost {boost} vs {reference}");
    }

    #[test]
    fn live_gain_changes_apply() {
        let path = sine_wav("live.wav", 60.0, 0.5);
        let params = Arc::new(EqParams::new([0.0; 3]));
        let mut source = EqSource::new(decode(&path), params.clone());
        let before = peak(source.by_ref().take(8820));
        params.set([-12.0, 0.0, 0.0]);
        let after = peak(source.skip(8820).take(8820));
        assert!(after < before * 0.35, "after {after} vs before {before}");
    }

    #[test]
    fn seeking_is_forwarded() {
        let path = sine_wav("seek.wav", 440.0, 1.0);
        let mut source = EqSource::new(decode(&path), Arc::new(EqParams::new([3.0, 0.0, -3.0])));
        source.try_seek(Duration::from_millis(500)).unwrap();
        let remaining = source.count();
        // About half a second of stereo samples remains.
        assert!((remaining as i64 - 44_100).abs() < 2_000, "remaining {remaining}");
    }
}
