import XCTest
import WhoopStore
@testable import Strand

@MainActor
final class TrainingRunSummaryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func row(_ sport: String = "Running", age: Int = 3600, distance: Double? = 5000,
                     duration: Double? = 1800) -> WorkoutRow {
        let start = Int(now.timeIntervalSince1970) - age
        return WorkoutRow(startTs: start, endTs: start + 1800, sport: sport, source: "manual",
                          durationS: duration, energyKcal: nil, avgHr: nil, maxHr: nil,
                          strain: nil, distanceM: distance, zonesJSON: nil, notes: nil, steps: nil)
    }

    func testCompletedRunsUseDistanceWeightedPaceAndIgnoreOtherSports() {
        let result = TrainingRunSummary.resolve([
            row(distance: 5000, duration: 1500), row("Treadmill run", age: 7200, distance: 10000, duration: 3600),
            row("Cycling", distance: 40000), row(age: 9 * 86400), row(age: -3600)
        ], now: now)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.distanceM, 15000)
        XCTAssertEqual(result.paceSecPerKm, 340)
        XCTAssertEqual(result.latest?.startTs, row().startTs)
    }

    func testAnyMissingDistanceKeepsTheAggregateAndPaceUnknown() {
        let result = TrainingRunSummary.resolve([row(), row(age: 7200, distance: nil)], now: now)
        XCTAssertEqual(result.count, 2)
        XCTAssertNil(result.distanceM)
        XCTAssertNil(result.paceSecPerKm)
    }

    func testEmptyHistoryAndInvalidDistanceAreNotInventedAsRunsOrPace() {
        XCTAssertEqual(TrainingRunSummary.resolve([], now: now).count, 0)
        XCTAssertNil(TrainingRunSummary.resolve([], now: now).distanceM)
        for distance in [Double.nan, Double.infinity, -1, 0] {
            XCTAssertNil(TrainingRunSummary.resolve([row(distance: distance)], now: now).paceSecPerKm)
        }
    }

    func testMissingDurationUsesRecordedStartAndEnd() {
        let result = TrainingRunSummary.resolve([row(duration: nil)], now: now)
        XCTAssertEqual(result.paceSecPerKm, 360)
    }
}
