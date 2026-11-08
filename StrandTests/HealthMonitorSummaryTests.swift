import XCTest
import StrandDesign
import StrandAnalytics
@testable import Strand

final class HealthMonitorSummaryTests: XCTestCase {
    private let day = "2026-11-08"

    private func reading(_ key: String, day: String = "2026-11-08",
                         band: VitalBands.Band = .inRange, value: Double? = 60,
                         caveat: String? = nil) -> BodyVitalReading {
        BodyVitalReading(key: key, label: key, unit: "", value: value, format: { String($0) },
                         banding: .init(band: band, basis: .personal, nights: 21),
                         metricColor: StrandPalette.statusPositive, day: day, source: nil,
                         missingCaption: "No reading", caveat: caveat)
    }

    func testGreenCompleteStateRequiresFiveCurrentVerifiedMetrics() {
        let full = HealthMonitorSummary.keys.sorted().map { reading($0) }
        XCTAssertEqual(HealthMonitorSummary(readings: full, day: day).state, .withinRange)
        XCTAssertEqual(HealthMonitorSummary(readings: Array(full.dropLast()), day: day).state, .partial)
        XCTAssertEqual(HealthMonitorSummary(readings: full + [full[0]], day: day).available, 5)
    }

    func testOldUnverifiedMissingAndNonfiniteMetricsCannotProduceHealthyStatus() {
        let values = [reading("hrv", day: "2026-11-07"), reading("rhr", caveat: "unverified"),
                      reading("spo2", value: .infinity), reading("skin", value: nil),
                      reading("resp", band: .noData)]
        let result = HealthMonitorSummary(readings: values, day: day)
        XCTAssertEqual(result.available, 0)
        XCTAssertEqual(result.state, .noData)
    }

    func testOutOfRangeRemainsVisibleEvenWithPartialCoverage() {
        let result = HealthMonitorSummary(readings: [reading("rhr", band: .outOfRange)], day: day)
        XCTAssertEqual(result.available, 1)
        XCTAssertEqual(result.state, .outOfRange)
    }
}
