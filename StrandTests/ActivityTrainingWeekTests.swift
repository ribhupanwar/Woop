import XCTest
import WhoopStore
@testable import Strand

final class ActivityTrainingWeekTests: XCTestCase {
    private func row(_ start: Int, sport: String, distance: Double? = nil) -> WorkoutRow {
        WorkoutRow(startTs: start, endTs: start + 600, sport: sport, source: "manual",
                   durationS: 600, energyKcal: nil, avgHr: nil, maxHr: nil, strain: nil,
                   distanceM: distance, zonesJSON: nil, notes: nil, steps: nil)
    }
    func testCalendarWeekExcludesOldAndFutureRowsAndWalkingDistance() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now))!
        let first = Int(start.timeIntervalSince1970)
        let last = Int(now.timeIntervalSince1970)
        let summary = ActivityTrainingWeek(rows: [
            row(first, sport: "Running", distance: 5000),
            row(last - 1000, sport: "Running"),
            row(last - 900, sport: "Walking", distance: 2000),
            row(last - 800, sport: "Strength Training"),
            row(first - 1, sport: "Running", distance: 10000),
            row(last + 1, sport: "Running", distance: 10000)
        ], now: now, calendar: calendar)
        XCTAssertEqual(summary.sessions, 4)
        XCTAssertEqual(summary.runs, 2)
        XCTAssertEqual(summary.runsWithDistance, 1)
        XCTAssertEqual(summary.runMeters, 5000)
    }
    func testMissingAndInvalidDistancesStayMissing() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let summary = ActivityTrainingWeek(rows: [
            row(1_799_999_000, sport: "Running"),
            row(1_799_998_000, sport: "Running", distance: .nan),
            row(1_799_997_000, sport: "Running", distance: -5)
        ], now: now, calendar: Calendar(identifier: .gregorian))
        XCTAssertEqual(summary.runs, 3)
        XCTAssertEqual(summary.runsWithDistance, 0)
        XCTAssertNil(summary.runMeters)
    }
}
