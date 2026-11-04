import XCTest
import WhoopProtocol
@testable import StrandAnalytics

final class MotionCadenceMinuteAccumulatorTests: XCTestCase {
    private func frame(second: Int, cadenceHz: Double?, phaseOffset: Double = 0) -> Whoop5ImuFrame {
        let samples = (0..<100).map { index -> RawImuSample in
            let t = Double(second * 100 + index) / 100.0
            let motion = cadenceHz.map { 0.18 * sin(2.0 * .pi * $0 * t + phaseOffset) } ?? 0
            return RawImuSample(ax: 0, ay: 0, az: 1.0 + motion, gx: 0, gy: 0, gz: 0)
        }
        return Whoop5ImuFrame(baseTs: 1_800_000 + second, sampleRateHz: 100, samples: samples)
    }

    func testSixtySecondsOfTwoHertzMotionProducesMinuteCadence() {
        var accumulator = MotionCadenceMinuteAccumulator()
        for second in 0..<60 {
            XCTAssertNil(accumulator.append(frame(second: second, cadenceHz: 2.0), averageBpm: 58))
        }
        let minute = accumulator.finish()
        XCTAssertEqual(minute?.sampleCount, 6_000)
        XCTAssertEqual(minute?.cadenceHz ?? 0, 2.0, accuracy: 0.08)
        XCTAssertGreaterThan(minute?.rhythmStrength ?? 0, 0.8)
        XCTAssertEqual(minute?.averageBpm, 58)
    }

    func testDirectionalWalkingSignalSurvivesConstantAccelerationMagnitude() {
        var accumulator = MotionCadenceMinuteAccumulator()
        for second in 0..<60 {
            let samples = (0..<100).map { index -> RawImuSample in
                let phase = 2.0 * .pi * 2.0 * (Double(second * 100 + index) / 100.0)
                // Wrist rotates rhythmically: acceleration magnitude remains exactly 1 g.
                return RawImuSample(ax: sin(phase), ay: cos(phase), az: 0,
                                    gx: 0, gy: 0, gz: 2.0 * sin(phase))
            }
            _ = accumulator.append(Whoop5ImuFrame(baseTs: 1_800_000 + second,
                                                  sampleRateHz: 100, samples: samples))
        }
        let minute = accumulator.finish()
        XCTAssertEqual(minute?.cadenceHz ?? 0, 2.0, accuracy: 0.08)
        XCTAssertGreaterThan(minute?.rhythmStrength ?? 0, 0.8)
    }

    func testPartialMinuteDoesNotInventCadence() {
        var accumulator = MotionCadenceMinuteAccumulator()
        for second in 0..<12 {
            _ = accumulator.append(frame(second: second, cadenceHz: 2.0))
        }
        let minute = accumulator.finish()
        XCTAssertEqual(minute?.sampleCount, 1_200)
        XCTAssertNil(minute?.cadenceHz)
        XCTAssertEqual(minute?.rhythmStrength, 0)
    }

    func testStationarySignalDoesNotProduceCadence() {
        var accumulator = MotionCadenceMinuteAccumulator()
        for second in 0..<60 {
            _ = accumulator.append(frame(second: second, cadenceHz: nil))
        }
        let minute = accumulator.finish()
        XCTAssertNil(minute?.cadenceHz)
        XCTAssertEqual(minute?.rhythmStrength, 0)
    }

    func testDuplicateAndOutOfOrderFramesAreIgnored() {
        var accumulator = MotionCadenceMinuteAccumulator()
        _ = accumulator.append(frame(second: 0, cadenceHz: 2.0))
        _ = accumulator.append(frame(second: 0, cadenceHz: 2.0))
        _ = accumulator.append(frame(second: -1, cadenceHz: 2.0))
        let minute = accumulator.finish()
        XCTAssertEqual(minute?.sampleCount, 100)
    }
}
