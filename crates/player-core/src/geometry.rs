//! Integer screen rectangles for window placement (physical pixels).

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct Rect {
    pub x: i32,
    pub y: i32,
    pub width: i32,
    pub height: i32,
}

impl Rect {
    pub const fn new(x: i32, y: i32, width: i32, height: i32) -> Self {
        Self { x, y, width, height }
    }

    pub fn right(&self) -> i32 {
        self.x + self.width
    }

    pub fn bottom(&self) -> i32 {
        self.y + self.height
    }

    pub fn center(&self) -> (i32, i32) {
        (self.x + self.width / 2, self.y + self.height / 2)
    }

    pub fn contains(&self, x: i32, y: i32) -> bool {
        x >= self.x && x < self.right() && y >= self.y && y < self.bottom()
    }

    pub fn lerp(&self, to: &Rect, t: f32) -> Rect {
        let mix = |a: i32, b: i32| (a as f32 + (b - a) as f32 * t).round() as i32;
        Rect {
            x: mix(self.x, to.x),
            y: mix(self.y, to.y),
            width: mix(self.width, to.width),
            height: mix(self.height, to.height),
        }
    }

    /// A rect of the given size centered within `self`.
    pub fn centered(&self, width: i32, height: i32) -> Rect {
        Rect::new(self.x + (self.width - width) / 2, self.y + (self.height - height) / 2, width, height)
    }

    /// A rect of the given size centered horizontally, `top_margin` below the top edge.
    pub fn top_centered(&self, width: i32, height: i32, top_margin: i32) -> Rect {
        Rect::new(self.x + (self.width - width) / 2, self.y + top_margin, width, height)
    }

    /// Moves `self` (without resizing) so it lies inside `area` where possible.
    pub fn clamped_within(&self, area: &Rect) -> Rect {
        let x = self.x.min(area.right() - self.width).max(area.x);
        let y = self.y.min(area.bottom() - self.height).max(area.y);
        Rect::new(x, y, self.width, self.height)
    }

    /// Moves `self` flush against any edge of `area` that it is within `threshold` of.
    pub fn snapped_to(&self, area: &Rect, threshold: i32) -> Rect {
        let mut snapped = *self;
        if (self.x - area.x).abs() < threshold {
            snapped.x = area.x;
        } else if (area.right() - self.right()).abs() < threshold {
            snapped.x = area.right() - self.width;
        }
        if (self.y - area.y).abs() < threshold {
            snapped.y = area.y;
        } else if (area.bottom() - self.bottom()).abs() < threshold {
            snapped.y = area.bottom() - self.height;
        }
        snapped
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const SCREEN: Rect = Rect::new(0, 0, 1920, 1040);

    #[test]
    fn snaps_near_edges_only() {
        let near_left_top = Rect::new(12, -5, 558, 180).snapped_to(&SCREEN, 20);
        assert_eq!((near_left_top.x, near_left_top.y), (0, 0));

        let near_right_bottom = Rect::new(1920 - 558 - 10, 1040 - 180 + 15, 558, 180);
        let snapped = near_right_bottom.snapped_to(&SCREEN, 20);
        assert_eq!((snapped.right(), snapped.bottom()), (1920, 1040));

        let middle = Rect::new(500, 400, 558, 180);
        assert_eq!(middle.snapped_to(&SCREEN, 20), middle);
    }

    #[test]
    fn centering_and_lerp() {
        let monitor = Rect::new(1920, 0, 2560, 1440);
        assert_eq!(monitor.top_centered(160, 46, 8), Rect::new(1920 + 1200, 8, 160, 46));
        assert_eq!(monitor.centered(980, 712), Rect::new(1920 + 790, 364, 980, 712));

        let a = Rect::new(0, 0, 100, 100);
        let b = Rect::new(100, 50, 200, 0);
        assert_eq!(a.lerp(&b, 0.0), a);
        assert_eq!(a.lerp(&b, 1.0), b);
        assert_eq!(a.lerp(&b, 0.5), Rect::new(50, 25, 150, 50));
        assert!(monitor.contains(1920, 0) && !monitor.contains(0, 0));

        let off_screen = Rect::new(1800, 900, 558, 180);
        assert_eq!(off_screen.clamped_within(&SCREEN), Rect::new(1920 - 558, 1040 - 180, 558, 180));
        assert_eq!(Rect::new(-50, -10, 100, 100).clamped_within(&SCREEN), Rect::new(0, 0, 100, 100));
    }
}
