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

    func testTenMinuteCadenceBoutEmitsOnceAndDoesNotRejectLowHeartRate() {
        var engine = MotionCadenceSessionEngine()
        var candidates: [MotionCadenceBoutDetector.Candidate] = []
        for second in 0..<(11 * 60) {
            candidates += engine.append(frame(second, frequency: 2.0), averageBpm: 52)
        }
        XCTAssertEqual(candidates.count, 1)
        XCTAssertEqual(candidates[0].kind, .walk)
        XCTAssertEqual(candidates[0].startTs, 0)
        XCTAssertEqual(candidates[0].endTs, 10 * 60)
        XCTAssertEqual(candidates[0].averageBpm, 52)
        XCTAssertTrue(engine.append(frame(11 * 60, frequency: 2.0), averageBpm: 52).isEmpty)
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
