//! The three window layouts and the cross-fade between them.

use std::time::Duration;

use super::theme::metrics;

pub const TRANSITION_DURATION: Duration = Duration::from_millis(360);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum WindowMode {
    Full,
    Mini,
    Island,
}

impl WindowMode {
    /// Logical size of the window in this mode.
    pub fn size(self) -> (f32, f32) {
        match self {
            WindowMode::Full => metrics::FULL_SIZE,
            WindowMode::Mini => metrics::MINI_SIZE,
            WindowMode::Island => metrics::ISLAND_SIZE,
        }
    }

    pub fn corner_radius(self) -> f32 {
        match self {
            WindowMode::Full => metrics::RADIUS_FULL,
            WindowMode::Mini => metrics::RADIUS_MINI,
            WindowMode::Island => metrics::RADIUS_ISLAND,
        }
    }
}

/// An in-flight mode change; `progress` is already eased (0 → 1).
#[derive(Debug, Clone, Copy)]
pub struct ModeTransition {
    pub from: WindowMode,
    pub to: WindowMode,
    pub progress: f32,
}

impl ModeTransition {
    pub fn corner_radius(&self) -> f32 {
        let (from, to) = (self.from.corner_radius(), self.to.corner_radius());
        from + (to - from) * self.progress
    }

    /// Whether the window surface should already use the island styling.
    pub fn island_shell(&self) -> bool {
        self.to == WindowMode::Island
    }
}

/// Opacity of a mode's content layer.
///
/// Outgoing content fades out while incoming content fades in. Going from the island to
/// the mini player, the island lingers and the mini player appears late, so neither is
/// drawn squeezed into the window while it is still small.
pub fn layer_opacity(layer: WindowMode, current: WindowMode, transition: Option<&ModeTransition>) -> f32 {
    let Some(t) = transition else {
        return if layer == current { 1.0 } else { 0.0 };
    };
    let p = t.progress;
    if layer == t.from {
        if layer == WindowMode::Island && t.to == WindowMode::Mini {
            if p < 0.62 { 1.0 } else { (1.0 - (p - 0.62) / 0.38).max(0.0) }
        } else {
            1.0 - p
        }
    } else if layer == t.to {
        if layer == WindowMode::Mini && t.from == WindowMode::Island {
            if p < 0.58 { 0.0 } else { ((p - 0.58) / 0.42).min(1.0) }
        } else {
            p
        }
    } else {
        0.0
    }
}
