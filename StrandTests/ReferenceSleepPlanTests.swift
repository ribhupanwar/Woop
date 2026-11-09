import XCTest
import StrandAnalytics
@testable import Strand

final class ReferenceSleepPlanTests: XCTestCase {
    private func ledger(_ debt: Double, need: Double = 480, nights: Bool = true) -> SleepDebtLedger {
        .init(balanceMin: -debt,
              nights: nights ? [.init(day: "2026-11-08", sleptMin: 420, deltaMin: -60)] : [],
              needMin: need)
    }
    func testMissingAndInvalidHistoryDoesNotCreateRecommendation() {
        XCTAssertNil(ReferenceSleepPlan(ledger: ledger(0, nights: false)))
        XCTAssertNil(ReferenceSleepPlan(ledger: ledger(.infinity)))
        XCTAssertNil(ReferenceSleepPlan(ledger: ledger(0, need: .nan)))
        XCTAssertNil(ReferenceSleepPlan(ledger: ledger(0, need: .greatestFiniteMagnitude)))
    }
    func testDebtAddsBoundedRepaymentWithoutReducingBaseNeed() throws {
        XCTAssertEqual(try XCTUnwrap(ReferenceSleepPlan(ledger: ledger(45))).targetMinutes, 525)
        XCTAssertEqual(try XCTUnwrap(ReferenceSleepPlan(ledger: ledger(600))).targetMinutes, 600)
        XCTAssertEqual(try XCTUnwrap(ReferenceSleepPlan(ledger: ledger(-60))).targetMinutes, 480)
    }
    func testBedtimePreservesActualDurationAcrossClockChange() throws {
        let plan = try XCTUnwrap(ReferenceSleepPlan(ledger: ledger(60)))
        let wake = Date(timeIntervalSince1970: 1793520000)
        XCTAssertEqual(wake.timeIntervalSince(plan.bedtime(wake: wake)), 9 * 3600)
    }
}
