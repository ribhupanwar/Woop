import Foundation

/// Experimental motion/rest segmentation, never a performed-set or repetition count.
/// All input is user-initiated and bounded by the Watch view's lifetime.
public struct MotionSetTrial: Sendable {
    private var last: Double?
    private var began: Double?
    private var lastMovement: Double?
    private var movingSeconds = 0.0
    public init() {}

    public mutating func reset() { self = Self() }

    /// Candidate only: at least eight seconds elapsed, three moving seconds, then four quiet seconds.
    /// Invalid, reordered or discontinuous samples reset evidence instead of manufacturing a set end.
    public mutating func ingest(timestamp: Double, accelerationG: Double) -> Bool {
        guard timestamp.isFinite, accelerationG.isFinite, accelerationG >= 0 else { reset(); return false }
        guard let previous = last else { last = timestamp; return false }
        let dt = timestamp - previous
        guard dt > 0, dt <= 0.5 else { reset(); last = timestamp; return false }
        last = timestamp
        if accelerationG >= 0.16 {
            if began == nil { began = timestamp }
            lastMovement = timestamp
            movingSeconds += min(dt, 0.1)
            return false
        }
        guard let began, let lastMovement, timestamp - lastMovement >= 4 else { return false }
        let candidate = timestamp - began >= 8 && movingSeconds >= 3
        reset()
        return candidate
    }
}
