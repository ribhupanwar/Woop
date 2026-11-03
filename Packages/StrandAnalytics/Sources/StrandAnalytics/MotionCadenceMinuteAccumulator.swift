import Foundation
import WhoopProtocol

/// Converts consecutive one-second WHOOP 5/MG IMU packets into the minute summaries
/// consumed by MotionCadenceBoutDetector. It is deliberately stateless across app launches:
/// callers own the capture lifecycle and must stop/flush it on disconnect.
public struct MotionCadenceMinuteAccumulator {
    private var minuteStart: Int?
    private var magnitudes: [Double] = []
    private var sampleCount = 0
    private var averageHeartRates: [Int] = []
    private var lastFrameTimestamp: Int?

    public init() {}

    /// Append one verified live IMU packet. A completed minute is returned when the packet
    /// crosses a minute boundary. Duplicate and out-of-order packet timestamps are ignored.
    public mutating func append(_ frame: Whoop5ImuFrame,
                                averageBpm: Int? = nil) -> MotionCadenceMinute? {
        guard frame.sampleRateHz == 100, !frame.samples.isEmpty else { return nil }
        guard lastFrameTimestamp.map({ frame.baseTs > $0 }) ?? true else { return nil }
        lastFrameTimestamp = frame.baseTs
        let bucket = (frame.baseTs / 60) * 60
        var completed: MotionCadenceMinute?
        if let current = minuteStart, bucket != current {
            completed = summarize()
            resetMinute()
        }
        if minuteStart == nil { minuteStart = bucket }
        for sample in frame.samples {
            let magnitude = sqrt(sample.ax * sample.ax + sample.ay * sample.ay + sample.az * sample.az)
            magnitudes.append(magnitude)
        }
        sampleCount += frame.samples.count
        if let averageBpm, (30...220).contains(averageBpm) {
            averageHeartRates.append(averageBpm)
        }
        return completed
    }

    /// Flush the final partial minute. The detector itself rejects minutes with too few samples.
    public mutating func finish() -> MotionCadenceMinute? {
        defer { resetMinute(); lastFrameTimestamp = nil }
        return summarize()
    }

    private mutating func resetMinute() {
        minuteStart = nil
        magnitudes.removeAll(keepingCapacity: true)
        sampleCount = 0
        averageHeartRates.removeAll(keepingCapacity: true)
    }

    private func summarize() -> MotionCadenceMinute? {
        guard let minuteStart else { return nil }
        guard sampleCount >= MotionCadenceBoutDetector.minimumSamplesPerMinute,
              magnitudes.count >= MotionCadenceBoutDetector.minimumSamplesPerMinute else {
            return MotionCadenceMinute(startTs: minuteStart, cadenceHz: nil,
                                       rhythmStrength: 0, sampleCount: sampleCount,
                                       averageBpm: meanHeartRate())
        }

        let mean = magnitudes.reduce(0, +) / Double(magnitudes.count)
        let signal = magnitudes.map { $0 - mean }
        let energy = signal.reduce(0) { $0 + $1 * $1 }
        guard energy > 1e-8 else {
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
            for i in 0..<(signal.count - lag) {
                let a = signal[i], b = signal[i + lag]
                cross += a * b
                leftEnergy += a * a
                rightEnergy += b * b
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
