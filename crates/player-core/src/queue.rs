//! Playback queue: track order, repeat-one, and shuffle with back/forward history.

use std::path::{Path, PathBuf};

use fastrand::Rng;

/// What the player should do after the user presses "previous".
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Previous {
    /// Load and play the track at this index.
    Play(usize),
    /// Seek the current track back to the start (shuffle mode with no history left).
    Restart,
}

/// What the player should do when the current track finishes on its own.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum TrackEnd {
    /// Replay the current track (repeat-one is on).
    Repeat,
    /// Load and play the track at this index.
    Play(usize),
}

/// Result of removing a track from the queue.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Removed {
    /// The removed track was not the current one; nothing needs to change in the player.
    Other,
    /// The current track was removed. Play the given index, or stop if the queue is now empty.
    Current(Option<usize>),
}

#[derive(Debug, Default, Clone)]
pub struct PlayQueue {
    tracks: Vec<PathBuf>,
    current: usize,
    repeat_one: bool,
    shuffle: bool,
    history: Vec<usize>,
    history_pos: Option<usize>,
}

impl PlayQueue {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn tracks(&self) -> &[PathBuf] {
        &self.tracks
    }

    pub fn len(&self) -> usize {
        self.tracks.len()
    }

    pub fn is_empty(&self) -> bool {
        self.tracks.is_empty()
    }

    /// Index of the current track, or `None` when the queue is empty.
    pub fn current(&self) -> Option<usize> {
        (!self.tracks.is_empty()).then_some(self.current)
    }

    pub fn current_path(&self) -> Option<&Path> {
        self.tracks.get(self.current).map(PathBuf::as_path)
    }

    pub fn repeat_one(&self) -> bool {
        self.repeat_one
    }

    pub fn shuffle(&self) -> bool {
        self.shuffle
    }

    /// Replaces all tracks and selects the first one.
    pub fn set_tracks(&mut self, tracks: Vec<PathBuf>) {
        self.tracks = tracks;
        self.current = 0;
        self.reset_history();
    }

    /// Selects a track explicitly (e.g. clicked in the playlist). Returns false if out of range.
    pub fn select(&mut self, index: usize) -> bool {
        if index >= self.tracks.len() {
            return false;
        }
        self.current = index;
        self.record(index);
        true
    }

    /// Advances to the next track and returns its index.
    ///
    /// In shuffle mode this first walks forward through history (after "previous" was used),
    /// then picks a random track that differs from the current one.
    pub fn next(&mut self, rng: &mut Rng) -> Option<usize> {
        if self.tracks.is_empty() {
            return None;
        }
        if self.shuffle {
            match self.history_pos {
                Some(pos) if pos + 1 < self.history.len() => {
                    self.history_pos = Some(pos + 1);
                    self.current = self.history[pos + 1];
                }
                _ => {
                    self.current = self.random_other_index(rng);
                    self.record(self.current);
                }
            }
        } else {
            self.current = (self.current + 1) % self.tracks.len();
        }
        Some(self.current)
    }

    pub fn previous(&mut self) -> Option<Previous> {
        if self.tracks.is_empty() {
            return None;
        }
        if self.shuffle {
            return Some(match self.history_pos {
                Some(pos) if pos > 0 => {
                    self.history_pos = Some(pos - 1);
                    self.current = self.history[pos - 1];
                    Previous::Play(self.current)
                }
                _ => Previous::Restart,
            });
        }
        let len = self.tracks.len();
        self.current = (self.current + len - 1) % len;
        Some(Previous::Play(self.current))
    }

    pub fn on_track_end(&mut self, rng: &mut Rng) -> Option<TrackEnd> {
        if self.tracks.is_empty() {
            return None;
        }
        if self.repeat_one {
            return Some(TrackEnd::Repeat);
        }
        self.next(rng).map(TrackEnd::Play)
    }

    pub fn remove(&mut self, index: usize) -> Option<Removed> {
        if index >= self.tracks.len() {
            return None;
        }
        self.tracks.remove(index);
        let removed_current = index == self.current;
        if self.tracks.is_empty() {
            self.current = 0;
        } else if removed_current {
            self.current %= self.tracks.len();
        } else if index < self.current {
            self.current -= 1;
        }
        // History indices are stale after a removal; restart it from the current track.
        self.reset_history();

        Some(if removed_current { Removed::Current(self.current()) } else { Removed::Other })
    }

    /// Enables or disables repeat-one. Enabling it turns shuffle off (the two are exclusive).
    pub fn set_repeat_one(&mut self, enabled: bool) {
        if enabled && self.shuffle {
            self.shuffle = false;
            self.reset_history();
        }
        self.repeat_one = enabled;
    }

    /// Enables or disables shuffle. Enabling it turns repeat-one off (the two are exclusive).
    pub fn set_shuffle(&mut self, enabled: bool) {
        if enabled && self.repeat_one {
            self.repeat_one = false;
        }
        self.shuffle = enabled;
        self.reset_history();
    }

    fn reset_history(&mut self) {
        self.history.clear();
        self.history_pos = None;
        if !self.tracks.is_empty() {
            self.record(self.current);
        }
    }

    fn random_other_index(&self, rng: &mut Rng) -> usize {
        let len = self.tracks.len();
        if len <= 1 {
            return self.current;
        }
        // Pick from the other len-1 tracks without retrying.
        let pick = rng.usize(0..len - 1);
        if pick >= self.current { pick + 1 } else { pick }
    }

    /// Records a visit in shuffle history, discarding any "forward" entries.
    fn record(&mut self, index: usize) {
        if !self.shuffle || index >= self.tracks.len() {
            return;
        }
        if let Some(pos) = self.history_pos
            && self.history.get(pos) == Some(&index)
        {
            return;
        }
        let keep = self.history_pos.map_or(0, |pos| pos + 1);
        self.history.truncate(keep);
        self.history.push(index);
        self.history_pos = Some(self.history.len() - 1);
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn queue(n: usize) -> PlayQueue {
        let mut q = PlayQueue::new();
        q.set_tracks((0..n).map(|i| PathBuf::from(format!("{i}.mp3"))).collect());
        q
    }

    #[test]
    fn sequential_wraps_both_ways() {
        let mut rng = Rng::with_seed(1);
        let mut q = queue(3);
        assert_eq!(q.current(), Some(0));
        assert_eq!(q.next(&mut rng), Some(1));
        assert_eq!(q.next(&mut rng), Some(2));
        assert_eq!(q.next(&mut rng), Some(0));
        assert_eq!(q.previous(), Some(Previous::Play(2)));
    }

    #[test]
    fn empty_queue_is_inert() {
        let mut rng = Rng::with_seed(1);
        let mut q = PlayQueue::new();
        assert_eq!(q.current(), None);
        assert_eq!(q.next(&mut rng), None);
        assert_eq!(q.previous(), None);
        assert_eq!(q.on_track_end(&mut rng), None);
        assert_eq!(q.remove(0), None);
        assert!(!q.select(0));
    }

    #[test]
    fn repeat_one_replays() {
        let mut rng = Rng::with_seed(1);
        let mut q = queue(3);
        q.set_repeat_one(true);
        assert_eq!(q.on_track_end(&mut rng), Some(TrackEnd::Repeat));
        q.set_repeat_one(false);
        assert_eq!(q.on_track_end(&mut rng), Some(TrackEnd::Play(1)));
    }

    #[test]
    fn repeat_and_shuffle_are_exclusive() {
        let mut q = queue(3);
        q.set_repeat_one(true);
        q.set_shuffle(true);
        assert!(q.shuffle() && !q.repeat_one());
        q.set_repeat_one(true);
        assert!(!q.shuffle() && q.repeat_one());
    }

    #[test]
    fn shuffle_never_repeats_current() {
        let mut rng = Rng::with_seed(42);
        let mut q = queue(5);
        q.set_shuffle(true);
        for _ in 0..200 {
            let before = q.current().unwrap();
            let after = q.next(&mut rng).unwrap();
            assert_ne!(before, after);
        }
    }

    #[test]
    fn shuffle_single_track_stays() {
        let mut rng = Rng::with_seed(42);
        let mut q = queue(1);
        q.set_shuffle(true);
        assert_eq!(q.next(&mut rng), Some(0));
    }

    #[test]
    fn shuffle_history_back_and_forward() {
        let mut rng = Rng::with_seed(7);
        let mut q = queue(10);
        q.set_shuffle(true);
        let a = q.current().unwrap();
        let b = q.next(&mut rng).unwrap();
        let c = q.next(&mut rng).unwrap();

        assert_eq!(q.previous(), Some(Previous::Play(b)));
        assert_eq!(q.previous(), Some(Previous::Play(a)));
        assert_eq!(q.previous(), Some(Previous::Restart));
        assert_eq!(q.current(), Some(a));

        // Forward replays history before picking new random tracks.
        assert_eq!(q.next(&mut rng), Some(b));
        assert_eq!(q.next(&mut rng), Some(c));
    }

    #[test]
    fn shuffle_select_truncates_forward_history() {
        let mut rng = Rng::with_seed(3);
        let mut q = queue(10);
        q.set_shuffle(true);
        let a = q.current().unwrap();
        let b = q.next(&mut rng).unwrap();
        q.next(&mut rng);
        assert_eq!(q.previous(), Some(Previous::Play(b)));

        let picked = (0..10).find(|i| ![a, b].contains(i)).unwrap();
        assert!(q.select(picked));
        assert_eq!(q.previous(), Some(Previous::Play(b)));
        assert_eq!(q.next(&mut rng), Some(picked));
    }

    #[test]
    fn remove_before_current_shifts_index() {
        let mut q = queue(4);
        q.select(2);
        assert_eq!(q.remove(0), Some(Removed::Other));
        assert_eq!(q.current(), Some(1));
        assert_eq!(q.current_path(), Some(Path::new("2.mp3")));
    }

    #[test]
    fn remove_after_current_keeps_index() {
        let mut q = queue(4);
        q.select(1);
        assert_eq!(q.remove(3), Some(Removed::Other));
        assert_eq!(q.current(), Some(1));
    }

    #[test]
    fn remove_current_moves_to_following_track() {
        let mut q = queue(3);
        q.select(1);
        assert_eq!(q.remove(1), Some(Removed::Current(Some(1))));
        assert_eq!(q.current_path(), Some(Path::new("2.mp3")));

        // Removing the last track wraps to the first.
        q.select(1);
        assert_eq!(q.remove(1), Some(Removed::Current(Some(0))));
    }

    #[test]
    fn remove_only_track_empties_queue() {
        let mut q = queue(1);
        assert_eq!(q.remove(0), Some(Removed::Current(None)));
        assert!(q.is_empty());
        assert_eq!(q.current(), None);
    }

    #[test]
    fn remove_resets_shuffle_history() {
        let mut rng = Rng::with_seed(9);
        let mut q = queue(6);
        q.set_shuffle(true);
        q.next(&mut rng);
        q.next(&mut rng);
        q.remove(q.current().unwrap());
        assert_eq!(q.previous(), Some(Previous::Restart));
    }
}
