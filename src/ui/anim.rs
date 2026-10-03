//! Minimal time-based tweening for view state (opacity, offsets, sizes).
//!
//! Views keep `Tween`s in their state, read `value()` while rendering and call
//! `window.request_animation_frame()` while any of them `is_running()`.

use std::time::{Duration, Instant};

use player_core::easing;

pub type Easing = fn(f32) -> f32;

#[derive(Debug, Clone, Copy)]
pub struct Tween {
    from: f32,
    to: f32,
    start: Instant,
    duration: Duration,
    ease: Easing,
}

impl Tween {
    /// A tween resting at `value`.
    pub fn settled(value: f32) -> Self {
        Self {
            from: value,
            to: value,
            start: Instant::now(),
            duration: Duration::ZERO,
            ease: easing::out_cubic,
        }
    }

    pub fn progress(&self) -> f32 {
        if self.duration.is_zero() {
            return 1.0;
        }
        (self.start.elapsed().as_secs_f32() / self.duration.as_secs_f32()).min(1.0)
    }

    pub fn value(&self) -> f32 {
        easing::lerp(self.from, self.to, (self.ease)(self.progress()))
    }

    pub fn is_running(&self) -> bool {
        self.progress() < 1.0
    }

    /// Animates from the current value to `to`. Does nothing if already heading there.
    pub fn animate_to(&mut self, to: f32, duration: Duration, ease: Easing) {
        if self.to == to {
            return;
        }
        *self = Self { from: self.value(), to, start: Instant::now(), duration, ease };
    }

    pub fn jump_to(&mut self, value: f32) {
        *self = Self::settled(value);
    }
}
