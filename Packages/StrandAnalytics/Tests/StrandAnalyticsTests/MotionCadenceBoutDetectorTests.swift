import XCTest
@testable import StrandAnalytics

final class MotionCadenceBoutDetectorTests: XCTestCase {
    private func minute(_ i: Int, cadence: Double? = 1.8, strength: Double = 0.55,
                        samples: Int = 6_000, bpm: Int? = 68) -> MotionCadenceMinute {
        .init(startTs: 1_000_000 + i * 60, cadenceHz: cadence, rhythmStrength: strength,
              sampleCount: samples, averageBpm: bpm)
    }

    func testTenMinuteEasyWalkSurvivesLowHeartRate() {
        let rows = (0..<10).map { minute($0, bpm: 68) }
        let result = MotionCadenceBoutDetector.detect(rows, restingBpm: 65)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].kind, .walk)
        XCTAssertEqual(result[0].hrElevationBpm, 3)
        XCTAssertEqual(result[0].durationMinutes, 10)
    }

    func testNineMinutesDoesNotTrigger() {
        XCTAssertTrue(MotionCadenceBoutDetector.detect((0..<9).map { minute($0) }).isEmpty)
    }

    func testWeakRhythmAndInsufficientSamplesDoNotTrigger() {
        let weak = (0..<12).map { minute($0, strength: 0.1) }
        let sparse = (0..<12).map { minute($0, samples: 500) }
        XCTAssertTrue(MotionCadenceBoutDetector.detect(weak).isEmpty)
        XCTAssertTrue(MotionCadenceBoutDetector.detect(sparse).isEmpty)
    }

    func testTwoMinuteGapIsToleratedButThreeMinuteGapSplits() {
        let tolerated = (0..<12).map { i in (4...5).contains(i) ? minute(i, cadence: nil) : minute(i) }
        XCTAssertEqual(MotionCadenceBoutDetector.detect(tolerated).count, 1)
        let split = (0..<15).map { i in (4...6).contains(i) ? minute(i, cadence: nil) : minute(i) }
        XCTAssertTrue(MotionCadenceBoutDetector.detect(split).isEmpty)
    }

    func testHighCadenceIsRunAndHRCanBeMissing() {
        let rows = (0..<12).map { minute($0, cadence: 2.8, bpm: nil) }
        XCTAssertEqual(MotionCadenceBoutDetector.detect(rows).first?.kind, .run)
    }

    func testCadenceBoutNeedsGPSBeforeItIsNamedWalkOrRun() {
        XCTAssertNil(MotionCadenceBoutDetector.classifyLocomotion(gpsDistanceM: nil, durationSeconds: 600))
        XCTAssertNil(MotionCadenceBoutDetector.classifyLocomotion(gpsDistanceM: 80, durationSeconds: 600))
        XCTAssertNil(MotionCadenceBoutDetector.classifyLocomotion(gpsDistanceM: 300, durationSeconds: 600))
    }

    func testGPSSpeedSeparatesWalkingFromRunning() {
        XCTAssertEqual(MotionCadenceBoutDetector.classifyLocomotion(gpsDistanceM: 1_000, durationSeconds: 600), .walk)
        XCTAssertEqual(MotionCadenceBoutDetector.classifyLocomotion(gpsDistanceM: 1_500, durationSeconds: 600), .run)
    }
}
