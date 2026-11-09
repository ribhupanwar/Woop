import XCTest
@testable import StrandDesign

final class MotionSetTrialTests: XCTestCase {
    func testMovementThenRestProducesOneCandidateOnly() {
        var trial = MotionSetTrial()
        var candidates = 0
        for i in 0...400 {
            if trial.ingest(timestamp: Double(i) / 25, accelerationG: i < 200 ? 0.3 : 0) { candidates += 1 }
        }
        XCTAssertEqual(candidates, 1)
    }
    func testRestAndBriefEquipmentAdjustmentDoNotSuggestASet() {
        var trial = MotionSetTrial()
        for i in 0...400 {
            XCTAssertFalse(trial.ingest(timestamp: Double(i) / 25, accelerationG: (50...60).contains(i) ? 0.3 : 0))
        }
    }
    func testDropoutAndPauseCannotCompletePreviousMotion() {
        var trial = MotionSetTrial()
        for i in 0...200 { _ = trial.ingest(timestamp: Double(i) / 25, accelerationG: 0.3) }
        for i in 0...150 { XCTAssertFalse(trial.ingest(timestamp: 20 + Double(i) / 25, accelerationG: 0)) }
        trial.reset()
        XCTAssertFalse(trial.ingest(timestamp: .nan, accelerationG: 0.3))
        XCTAssertFalse(trial.ingest(timestamp: 30, accelerationG: .infinity))
    }
    func testContinuousMotionDoesNotCountRepsOrCloseASet() {
        var trial = MotionSetTrial()
        for i in 0...1500 { XCTAssertFalse(trial.ingest(timestamp: Double(i) / 25, accelerationG: 0.3)) }
    }
}
