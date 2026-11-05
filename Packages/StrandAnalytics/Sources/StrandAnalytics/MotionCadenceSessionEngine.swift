import Foundation
import WhoopProtocol

/// Stateful bridge between verified live WHOOP 5/MG IMU frames and the ten-minute
/// cadence bout detector. The BLE owner controls when frames are admitted; this type
/// deliberately does not start BLE commands or interpret unverified/offload packets.
public struct MotionCadenceSessionEngine {
    private var accumulator = MotionCadenceMinuteAccumulator()
    private var minutes: [MotionCadenceMinute] = []
    private var emittedEndByKey: [String: Int] = [:]
    private var preArmStartTs: Int?
    private var preArmLastFrameTs: Int?
    private var preArmLastCadenceHz: Double?
    private var preArmConsecutiveFrames = 0
    private let retentionMinutes: Int

    public init(retentionMinutes: Int = 1_440) {
        self.retentionMinutes = max(MotionCadenceBoutDetector.minimumDurationMinutes, retentionMinutes)
    }

    /// Early gait signal for GPS pre-arming only; the ten-minute detector remains the sole
    /// authority that creates an activity row.
    public mutating func preliminaryMovementStart(for frame: Whoop5ImuFrame) -> Int? {
        guard frame.sampleRateHz == 100, !frame.samples.isEmpty,
              let cadence = preliminaryCadenceHz(frame) else {
            preArmStartTs = nil
            preArmLastFrameTs = nil
            preArmLastCadenceHz = nil
            preArmConsecutiveFrames = 0
            return nil
        }
        if let last = preArmLastFrameTs, frame.baseTs > last, frame.baseTs - last <= 2,
           let previous = preArmLastCadenceHz, abs(cadence - previous) <= 0.55 {
            preArmConsecutiveFrames += 1
        } else {
            preArmStartTs = frame.baseTs
            preArmConsecutiveFrames = 1
        }
        preArmLastFrameTs = frame.baseTs
        preArmLastCadenceHz = cadence
        return preArmConsecutiveFrames >= 3 ? preArmStartTs : nil
    }

    private func preliminaryCadenceHz(_ frame: Whoop5ImuFrame) -> Double? {
        let samples = frame.samples
        guard samples.count >= 90 else { return nil }
        let axes: [[Double]] = [
            samples.map(\.ax), samples.map(\.ay), samples.map(\.az),
            samples.map(\.gx), samples.map(\.gy), samples.map(\.gz)
        ]
        let signals = axes.map { axis -> [Double] in
            let mean = axis.reduce(0, +) / Double(axis.count)
            return axis.map { $0 - mean }
        }
        var bestLag = 0, bestStrength = 0.0
        for lag in 29...83 where lag < samples.count {
            var cross = 0.0, left = 0.0, right = 0.0
            for signal in signals {
                for i in 0..<(signal.count - lag) {
                    let a = signal[i], b = signal[i + lag]
                    cross += a * b; left += a * a; right += b * b
                }
            }
            let denominator = sqrt(left * right)
            let strength = denominator > 1e-9 ? cross / denominator : 0
            if strength > bestStrength { bestStrength = strength; bestLag = lag }
        }
        guard bestStrength >= 0.65, bestLag > 0 else { return nil }
        let cadence = 100.0 / Double(bestLag)
        return (MotionCadenceBoutDetector.minimumCadenceHz...MotionCadenceBoutDetector.maximumCadenceHz)
            .contains(cadence) ? cadence : nil
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
        preArmStartTs = nil
        preArmLastFrameTs = nil
        preArmLastCadenceHz = nil
        preArmConsecutiveFrames = 0
        return result
    }

    public mutating func reset() {
        accumulator = MotionCadenceMinuteAccumulator()
        minutes.removeAll(keepingCapacity: true)
        emittedEndByKey.removeAll(keepingCapacity: true)
        preArmStartTs = nil
        preArmLastFrameTs = nil
        preArmLastCadenceHz = nil
        preArmConsecutiveFrames = 0
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
