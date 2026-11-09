import XCTest
import StrandAnalytics
@testable import Strand

final class WatchRunningPlanLayoutTests: XCTestCase {
    func testGPSIntervalsPreserveEveryPhaseAndTarget() throws {
        let phases = RunningProgramStarter.distanceIntervals
        let layout = try XCTUnwrap(WatchRunningPlanLayout(phases: phases))
        XCTAssertEqual(layout.warmup?.seconds, 600)
        XCTAssertEqual(layout.cooldown?.seconds, 300)
        XCTAssertEqual(layout.intervals.count, 12)
        XCTAssertEqual(layout.intervals.map(\.id), Array(phases.dropFirst().dropLast()).map(\.id))
        XCTAssertEqual(layout.intervals.compactMap(\.meters).reduce(0, +), 3600)
    }
    func testInteriorWarmupIsRejectedInsteadOfRelabelledAsWork() {
        XCTAssertNil(WatchRunningPlanLayout(phases: [
            .init(kind: .work, seconds: 30), .init(kind: .warmup, seconds: 30), .init(kind: .work, seconds: 30)
        ]))
        XCTAssertNil(WatchRunningPlanLayout(phases: [.init(kind: .warmup, seconds: 300)]))
    }
    func testOpenAndMalformedGoalsAreNotExported() {
        XCTAssertNil(WatchRunningPlanLayout(phases: []))
        XCTAssertNil(WatchRunningPlanLayout(phases: [.init(kind: .work, seconds: .nan)]))
        XCTAssertNil(WatchRunningPlanLayout(phases: [.init(kind: .work, seconds: 30, meters: 400)]))
    }
    func testWorkOnlyPlanDoesNotAcquireInventedWarmupOrCooldown() throws {
        let layout = try XCTUnwrap(WatchRunningPlanLayout(phases: [.init(kind: .work, seconds: 1800)]))
        XCTAssertNil(layout.warmup)
        XCTAssertNil(layout.cooldown)
        XCTAssertEqual(layout.intervals.count, 1)
        XCTAssertEqual(layout.intervals[0].seconds, 1800)
    }
}
