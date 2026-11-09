import XCTest
import StrandAnalytics
@testable import Strand

final class RunningProgramStarterTests: XCTestCase {
    func testDistanceIntervalsRequireGPSAndKeepWarmupTimed() {
        let phases = RunningProgramStarter.distanceIntervals
        let plan = WorkoutGuidance(phases: phases)
        XCTAssertTrue(plan.isValid)
        XCTAssertTrue(plan.requiresGPS)
        XCTAssertEqual(phases.filter { $0.kind == .work }.count, 6)
        XCTAssertEqual(phases.compactMap(\.meters).reduce(0, +), 3600)
        XCTAssertEqual(phases.compactMap(\.seconds).reduce(0, +), 900)
        XCTAssertTrue(phases.allSatisfy { ($0.seconds == nil) != ($0.meters == nil) })
        XCTAssertEqual(Set(phases.map(\.id)).count, phases.count)
    }

    func testStartersHaveHonestDurationsAndRequireNoSyntheticGPS() {
        let totals: [RunningProgramStarter: Double] = [.easy: 2100, .intervals: 2280, .tempo: 2100, .longRun: 3600]
        for starter in RunningProgramStarter.allCases {
            let phases = starter.phases
            let plan = WorkoutGuidance(phases: phases)
            XCTAssertTrue(plan.isValid)
            XCTAssertFalse(plan.requiresGPS)
            XCTAssertEqual(phases.compactMap(\.seconds).reduce(0, +), totals[starter] ?? -1)
            XCTAssertEqual(phases.first?.kind, .warmup)
            XCTAssertEqual(phases.last?.kind, .cooldown)
        }
        XCTAssertEqual(RunningProgramStarter.intervals.phases.filter { $0.kind == .work }.count, 6)
    }
}
