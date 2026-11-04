import Foundation
import WhoopProtocol

/// Converts consecutive one-second WHOOP 5/MG IMU packets into the minute summaries
/// consumed by MotionCadenceBoutDetector. Callers own the capture lifecycle.
public struct MotionCadenceMinuteAccumulator {
    private var minuteStart: Int?
    // Keep the six signed sensor axes. Acceleration magnitude alone is almost constant
    // (~1 g) during wrist rotation, which erases much of the gait signal.
    private var axes: [[Double]] = Array(repeating: [], count: 6)
    private var sampleCount = 0
    private var averageHeartRates: [Int] = []
    private var lastFrameTimestamp: Int?

    public init() {}

    /// Append one verified live IMU packet. Duplicate and out-of-order packet timestamps are ignored.
    public mutating func append(_ frame: Whoop5ImuFrame,
                                averageBpm: Int? = nil) -> MotionCadenceMinute? {
        guard frame.sampleRateHz == 100, !frame.samples.isEmpty else { return nil }
        guard lastFrameTimestamp.map({ frame.baseTs > $0 }) ?? true else { return nil }
        lastFrameTimestamp = frame.baseTs
        // Anchor each 60-second window to the first live frame, not the wall-clock
        // minute. Epoch-aligned buckets discard the first/last partial minute whenever a
        // user starts walking between :00 boundaries, making a real 10-minute bout require
        // 11+ minutes before it can qualify.
        var bucket = frame.baseTs
        var completed: MotionCadenceMinute?
        if let current = minuteStart {
            let elapsed = frame.baseTs - current
            if elapsed >= 60 {
                completed = summarize()
                resetMinute()
                bucket = frame.baseTs
            } else {
                bucket = current
            }
        }
        if minuteStart == nil { minuteStart = bucket }
        for sample in frame.samples {
            axes[0].append(sample.ax); axes[1].append(sample.ay); axes[2].append(sample.az)
            axes[3].append(sample.gx); axes[4].append(sample.gy); axes[5].append(sample.gz)
        }
        sampleCount += frame.samples.count
        if let averageBpm, (30...220).contains(averageBpm) {
            averageHeartRates.append(averageBpm)
        }
        return completed
    }

    /// Flush the final partial minute. The detector rejects minutes with too few samples.
    public mutating func finish() -> MotionCadenceMinute? {
        defer { resetMinute(); lastFrameTimestamp = nil }
        return summarize()
    }

    private mutating func resetMinute() {
        minuteStart = nil
        for i in axes.indices { axes[i].removeAll(keepingCapacity: true) }
        sampleCount = 0
        averageHeartRates.removeAll(keepingCapacity: true)
    }

    private func summarize() -> MotionCadenceMinute? {
        guard let minuteStart else { return nil }
        guard sampleCount >= MotionCadenceBoutDetector.minimumSamplesPerMinute,
              axes.allSatisfy({ $0.count == sampleCount }) else {
            return MotionCadenceMinute(startTs: minuteStart, cadenceHz: nil,
                                       rhythmStrength: 0, sampleCount: sampleCount,
                                       averageBpm: meanHeartRate())
        }

        // Remove each axis' own DC offset (gravity/orientation and sensor bias), then
        // correlate all six signed axes together. This preserves directional gait motion
        // while using gyro as an independent wrist-rotation signal.
        let signals: [[Double]] = axes.map { axis in
            let mean = axis.reduce(0, +) / Double(axis.count)
            return axis.map { $0 - mean }
        }
        let totalEnergy = signals.reduce(0.0) { partial, signal in
            partial + signal.reduce(0.0) { $0 + $1 * $1 }
        }
        guard totalEnergy > 1e-8 else {
            return MotionCadenceMinute(startTs: minuteStart, cadenceHz: nil,
                                       rhythmStrength: 0, sampleCount: sampleCount,
                                       averageBpm: meanHeartRate())
        }

        let minLag = Int((100.0 / MotionCadenceBoutDetector.maximumCadenceHz).rounded(.up))
        let maxLag = Int((100.0 / MotionCadenceBoutDetector.minimumCadenceHz).rounded(.down))
        var bestLag = 0
        var bestStrength = 0.0
        for lag in minLag...maxLag {
            var cross = 0.0
            var leftEnergy = 0.0
            var rightEnergy = 0.0
            for signal in signals {
                for i in 0..<(signal.count - lag) {
                    let a = signal[i], b = signal[i + lag]
                    cross += a * b
                    leftEnergy += a * a
                    rightEnergy += b * b
                }
            }
            let denominator = sqrt(leftEnergy * rightEnergy)
            let strength = denominator > 0 ? cross / denominator : 0
            if strength > bestStrength {
                bestStrength = strength
                bestLag = lag
            }
        }
        let cadence = bestLag > 0 ? 100.0 / Double(bestLag) : nil
        return MotionCadenceMinute(startTs: minuteStart, cadenceHz: cadence,
                                   rhythmStrength: max(0, bestStrength),
                                   sampleCount: sampleCount, averageBpm: meanHeartRate())
    }

    private func meanHeartRate() -> Int? {
        guard !averageHeartRates.isEmpty else { return nil }
        return Int((Double(averageHeartRates.reduce(0, +)) /
                    Double(averageHeartRates.count)).rounded())
    }
}
