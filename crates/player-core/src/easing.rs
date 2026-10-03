//! Easing curves matching the Qt Quick animations of the original UI.

pub fn lerp(from: f32, to: f32, t: f32) -> f32 {
    from + (to - from) * t
}

pub fn in_out_cubic(t: f32) -> f32 {
    let t = t.clamp(0.0, 1.0);
    if t < 0.5 { 4.0 * t * t * t } else { 1.0 - (-2.0 * t + 2.0).powi(3) / 2.0 }
}

pub fn out_cubic(t: f32) -> f32 {
    1.0 - (1.0 - t.clamp(0.0, 1.0)).powi(3)
}

pub fn in_out_quad(t: f32) -> f32 {
    let t = t.clamp(0.0, 1.0);
    if t < 0.5 { 2.0 * t * t } else { 1.0 - (-2.0 * t + 2.0).powi(2) / 2.0 }
}

pub fn out_quad(t: f32) -> f32 {
    let t = t.clamp(0.0, 1.0);
    1.0 - (1.0 - t) * (1.0 - t)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn endpoints_and_midpoint() {
        for ease in [in_out_cubic, out_cubic, in_out_quad, out_quad] {
            assert_eq!(ease(0.0), 0.0);
            assert!((ease(1.0) - 1.0).abs() < 1e-6);
        }
        assert!((in_out_cubic(0.5) - 0.5).abs() < 1e-6);
        assert!((in_out_quad(0.5) - 0.5).abs() < 1e-6);
        assert_eq!(lerp(10.0, 20.0, 0.25), 12.5);
    }
}
