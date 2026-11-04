import XCTest
import WhoopProtocol
@testable import StrandAnalytics

final class MotionCadenceSessionEngineTests: XCTestCase {
    private func frame(_ second: Int, frequency: Double?) -> Whoop5ImuFrame {
        let samples = (0..<100).map { i -> RawImuSample in
            let t = Double(i) / 100.0
            let wave = frequency.map { 0.18 * sin(2 * .pi * $0 * (Double(second) + t)) } ?? 0
            return RawImuSample(ax: 1 + wave, ay: 0, az: 0, gx: 0, gy: 0, gz: 0)
        }
        return Whoop5ImuFrame(baseTs: second, sampleRateHz: 100, samples: samples)
    }

    func testTenMinuteCadenceBoutEmitsAndExtendsWithoutRejectingLowHeartRate() {
        var engine = MotionCadenceSessionEngine()
        var candidates: [MotionCadenceBoutDetector.Candidate] = []
        for second in 0..<(11 * 60) {
            candidates += engine.append(frame(second, frequency: 2.0), averageBpm: 52)
        }

        candidates += engine.append(frame(11 * 60, frequency: 2.0), averageBpm: 52)

        XCTAssertGreaterThanOrEqual(candidates.count, 2, "The qualified bout should be emitted initially and when its end time extends.")
        XCTAssertTrue(candidates.allSatisfy { $0.kind == .walk && $0.startTs == 0 })
        XCTAssertEqual(candidates.first?.endTs, 10 * 60)
        XCTAssertEqual(candidates.last?.endTs, 11 * 60)
        XCTAssertTrue(candidates.allSatisfy { $0.averageBpm == 52 })
        XCTAssertTrue(engine.append(frame(11 * 60, frequency: 2.0), averageBpm: 52).isEmpty,
                      "An unchanged candidate must not be emitted again.")
    }

    func testTenMinuteBoutQualifiesWhenWalkStartsBetweenClockMinuteBoundaries() {
        var engine = MotionCadenceSessionEngine()
        var candidates: [MotionCadenceBoutDetector.Candidate] = []

        // Start at :35, then provide exactly ten minutes of 100 Hz walking frames.
        // Include the first frame of the next window to finalize the tenth complete minute.
        for second in 35...635 {
            candidates += engine.append(frame(second, frequency: 2.0), averageBpm: 52)
        }

        XCTAssertFalse(candidates.isEmpty, "A ten-minute walk must qualify regardless of wall-clock alignment.")
        XCTAssertEqual(candidates.first?.startTs, 35)
        XCTAssertEqual(candidates.first?.endTs, 635)
        XCTAssertEqual(candidates.first?.durationMinutes, 10)
        XCTAssertTrue(candidates.allSatisfy { $0.kind == .walk })
    }

    func testThirtyMinuteBoutKeepsStableStartAndExtendsPastThreshold() {
        var engine = MotionCadenceSessionEngine()
        var candidates: [MotionCadenceBoutDetector.Candidate] = []
        for second in 0..<(31 * 60) {
            candidates += engine.append(frame(second, frequency: 2.0), averageBpm: 55)
        }

        XCTAssertFalse(candidates.isEmpty)
        XCTAssertTrue(candidates.allSatisfy { $0.startTs == 0 && $0.kind == .walk })
        XCTAssertGreaterThanOrEqual(candidates.last?.endTs ?? 0, 30 * 60)
    }

    func testStationaryMotionNeverCreatesBout() {
        var engine = MotionCadenceSessionEngine()
        var candidates: [MotionCadenceBoutDetector.Candidate] = []
        for second in 0..<(12 * 60) {
            candidates += engine.append(frame(second, frequency: nil), averageBpm: 48)
        }
        candidates += engine.finish()
        XCTAssertTrue(candidates.isEmpty)
    }

    func testPartialCaptureCannotCreateTenMinuteBout() {
        var engine = MotionCadenceSessionEngine()
        for second in 0..<(9 * 60) {
            XCTAssertTrue(engine.append(frame(second, frequency: 2.0), averageBpm: 55).isEmpty)
        }
        XCTAssertTrue(engine.finish().isEmpty)
    }
}
