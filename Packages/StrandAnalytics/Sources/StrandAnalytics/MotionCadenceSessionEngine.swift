import Foundation
import WhoopProtocol

/// Stateful bridge between verified live WHOOP 5/MG IMU frames and the ten-minute
/// cadence bout detector. The BLE owner controls when frames are admitted; this type
/// deliberately does not start BLE commands or interpret unverified/offload packets.
public struct MotionCadenceSessionEngine {
    private var accumulator = MotionCadenceMinuteAccumulator()
    private var minutes: [MotionCadenceMinute] = []
    private var emittedEndByKey: [String: Int] = [:]
    private let retentionMinutes: Int

    public init(retentionMinutes: Int = 1_440) {
        self.retentionMinutes = max(MotionCadenceBoutDetector.minimumDurationMinutes, retentionMinutes)
    }

    /// Feed one already-integrity-verified, live WHOOP 5/MG IMU frame.
    /// Returns a newly qualified bout and later end-time extensions for that same bout,
    /// without re-emitting an unchanged candidate.
    public mutating func append(_ frame: Whoop5ImuFrame,
                                averageBpm: Int? = nil,
                                restingBpm: Int? = nil) -> [MotionCadenceBoutDetector.Candidate] {
        guard let minute = accumulator.append(frame, averageBpm: averageBpm) else { return [] }
        minutes.append(minute)
        trim()
        return newlyDetected(restingBpm: restingBpm)
    }

    /// Flush the last minute when a capture session ends. Partial minutes remain ineligible
    /// because MotionCadenceBoutDetector enforces its 3,000-sample minimum.
    public mutating func finish(restingBpm: Int? = nil) -> [MotionCadenceBoutDetector.Candidate] {
        if let minute = accumulator.finish() { minutes.append(minute) }
        trim()
        let result = newlyDetected(restingBpm: restingBpm)
        minutes.removeAll(keepingCapacity: true)
        emittedEndByKey.removeAll(keepingCapacity: true)
        return result
    }

    public mutating func reset() {
        accumulator = MotionCadenceMinuteAccumulator()
        minutes.removeAll(keepingCapacity: true)
        emittedEndByKey.removeAll(keepingCapacity: true)
    }

    private mutating func trim() {
        if minutes.count > retentionMinutes {
            minutes.removeFirst(minutes.count - retentionMinutes)
        }
    }

    private mutating func newlyDetected(restingBpm: Int?) -> [MotionCadenceBoutDetector.Candidate] {
        MotionCadenceBoutDetector.detect(minutes, restingBpm: restingBpm).filter { candidate in
            let key = "\(candidate.startTs):\(candidate.kind.rawValue)"
            guard candidate.endTs > (emittedEndByKey[key] ?? Int.min) else { return false }
            emittedEndByKey[key] = candidate.endTs
            return true
        }
    }
}
