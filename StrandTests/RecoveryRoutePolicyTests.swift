import XCTest
@testable import Strand

/// Pins the dedicated Recovery destination without constructing SwiftUI navigation.
final class RecoveryRoutePolicyTests: XCTestCase {

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
