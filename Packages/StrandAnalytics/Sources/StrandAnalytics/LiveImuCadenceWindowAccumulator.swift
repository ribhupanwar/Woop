import Foundation
import WhoopProtocol

/// Builds complete minute-level cadence summaries from the live 1-second WHOOP 5/MG IMU frames.
///
/// This type is deliberately transport-agnostic: BLE owns the opt-in/start/stop lifecycle and calls
/// `ingest` only for integrity-verified, non-offload frames from an active detector session. It does
/// not start the strap stream, bypass the BLE write gate, or retain raw samples after a minute closes.
public struct LiveImuCadenceWindowAccumulator: Sendable {
    private var minuteStart: Int?
    private var samples: [RawImuSample] = []
    private var bpmTotal = 0
    private var bpmCount = 0
    private var lastAcceptedFrameTs: Int?

    public init() {}

    /// Add one decoded one-second frame. Returns the prior minute when a newer minute begins.
    /// Duplicate and out-of-order frames are ignored so retransmissions cannot inflate confidence.
    public mutating func ingest(_ frame: Whoop5ImuFrame, averageBpm: Int? = nil) -> MotionCadenceMinute? {
        guard frame.sampleRateHz == 100, frame.samples.count == Whoop5RawImu.sampleCount,
              frame.baseTs > 0 else { return nil }
        if let lastAcceptedFrameTs, frame.baseTs <= lastAcceptedFrameTs { return nil }

        let bucket = (frame.baseTs / 60) * 60
        var completed: MotionCadenceMinute?
        if let current = minuteStart, bucket < current { return nil }
        if let current = minuteStart, bucket > current {
            completed = finishCurrentMinute()
            resetMinute()
        }
        if minuteStart == nil { minuteStart = bucket }

        samples.append(contentsOf: frame.samples)
        if let averageBpm, (30...220).contains(averageBpm) {
            bpmTotal += averageBpm
            bpmCount += 1
        }
        lastAcceptedFrameTs = frame.baseTs
        return completed
    }

    /// Close the current bucket, typically on disconnect or detector-session stop.
    /// A partial minute is returned for diagnostics but will not qualify in the bout detector.
    public mutating func finish() -> MotionCadenceMinute? {
        let result = finishCurrentMinute()
        resetMinute()
        lastAcceptedFrameTs = nil
        return result
    }

    private mutating func finishCurrentMinute() -> MotionCadenceMinute? {
        guard let minuteStart, !samples.isEmpty else { return nil }
        let features = ImuFeatureExtractor.extract(samples, sampleRateHz: 100)
        let averageBpm = bpmCount > 0 ? Int((Double(bpmTotal) / Double(bpmCount)).rounded()) : nil
        return MotionCadenceMinute(startTs: minuteStart, cadenceHz: features.cadenceHz,
                                   rhythmStrength: features.cadenceStrength,
                                   sampleCount: features.sampleCount, averageBpm: averageBpm)
    }

    private mutating func resetMinute() {
        minuteStart = nil
        samples.removeAll(keepingCapacity: true)
        bpmTotal = 0
        bpmCount = 0
    }
}
