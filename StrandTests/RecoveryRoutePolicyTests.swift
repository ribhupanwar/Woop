import XCTest
@testable import Strand

/// Pins the dedicated Recovery destination without constructing SwiftUI navigation.
final class RecoveryRoutePolicyTests: XCTestCase {

    func testRecoveryWeekIncludesExactlySevenCivilDaysAcrossMonthBoundary() {
        XCTAssertEqual(RecoveryHistoryRange.week.dayKeys(endingOn: "2026-03-03"),
                       ["2026-02-25", "2026-02-26", "2026-02-27", "2026-02-28",
                        "2026-03-01", "2026-03-02", "2026-03-03"])
    }

    func testRecoveryMonthHasThirtySlotsIncludingMissingNights() {
        let keys = RecoveryHistoryRange.month.dayKeys(endingOn: "2026-11-07")
        XCTAssertEqual(keys.count, 30)
        XCTAssertEqual(keys.first, "2026-10-09")
        XCTAssertEqual(keys.last, "2026-11-07")
        XCTAssertEqual(Set(keys).count, 30)
    }

    func testRecoveryWindowIncludesLeapDayAndRejectsInvalidDay() {
        XCTAssertTrue(RecoveryHistoryRange.week.dayKeys(endingOn: "2028-03-01").contains("2028-02-29"))
        XCTAssertTrue(RecoveryHistoryRange.week.dayKeys(endingOn: "2026-02-30").isEmpty)
        XCTAssertTrue(RecoveryHistoryRange.week.dayKeys(endingOn: "").isEmpty)
    }

    func testUnscopedRecoveryMetricUsesDedicatedDetail() {
        XCTAssertTrue(RecoveryRoutePolicy.usesDedicatedDetail(metricKey: "recovery"))
    }

    func testOtherUnscopedMetricsKeepTheirExistingDetail() {
        XCTAssertFalse(RecoveryRoutePolicy.usesDedicatedDetail(metricKey: "strain"))
        XCTAssertFalse(RecoveryRoutePolicy.usesDedicatedDetail(metricKey: "sleep_performance"))
        XCTAssertFalse(RecoveryRoutePolicy.usesDedicatedDetail(metricKey: "Recovery"))
    }

    func testOnlyWhoopSourcedRecoveryUsesDedicatedDetail() {
        XCTAssertTrue(RecoveryRoutePolicy.usesDedicatedDetail(
            metricKey: "recovery", source: Repository.whoopSource
        ))
    }

    func testOtherSourcesDoNotGetWhoopRecoveryDetail() {
        XCTAssertFalse(RecoveryRoutePolicy.usesDedicatedDetail(
            metricKey: "recovery", source: "apple-health"
        ))
        XCTAssertFalse(RecoveryRoutePolicy.usesDedicatedDetail(
            metricKey: "recovery", source: "xiaomi-band"
        ))
    }

    func testDifferentMetricNeverUsesDedicatedRecoveryDetail() {
        XCTAssertFalse(RecoveryRoutePolicy.usesDedicatedDetail(
            metricKey: "steps", source: Repository.whoopSource
        ))
    }
}
