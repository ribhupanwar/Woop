import XCTest
import StrandDesign
import SwiftUI
#if canImport(AppKit)
import AppKit
#endif
@testable import Strand

final class ReferenceMetricTrendTests: XCTestCase {
    #if canImport(AppKit)
    @MainActor
    func testDashboardRowsRemainCompactWithComparison() {
        for card in [DashboardCard.hrv, .restingHr, .steps] {
            let view = NSHostingView(rootView: ReferenceDashboardMetricCard(
                card: card, value: "123", comparison: .init(value: "120", day: "2026-01-01", direction: 1))
                .frame(width: 350))
            let height = view.fittingSize.height
            XCTAssertGreaterThanOrEqual(height, 54)
            XCTAssertLessThanOrEqual(height, 64, "Metric rows must not grow a third comparison-date line")
        }
    }
    #endif

    func testTrendColorsRespectMetricDirection() {
        XCTAssertEqual(ReferenceMetricTrend.resolve(card: .hrv, direction: 1), .favorable)
        XCTAssertEqual(ReferenceMetricTrend.resolve(card: .hrv, direction: -1), .unfavorable)
        XCTAssertEqual(ReferenceMetricTrend.resolve(card: .restingHr, direction: -1), .favorable)
        XCTAssertEqual(ReferenceMetricTrend.resolve(card: .restingHr, direction: 1), .unfavorable)
        XCTAssertEqual(ReferenceMetricTrend.resolve(card: .steps, direction: 1), .favorable)
        XCTAssertEqual(ReferenceMetricTrend.resolve(card: .steps, direction: -1), .unfavorable)
        for card in DashboardCard.allCases {
            XCTAssertEqual(ReferenceMetricTrend.resolve(card: card, direction: 0), .unchanged)
        }
        for card in [DashboardCard.calories, .weight] {
            XCTAssertEqual(ReferenceMetricTrend.resolve(card: card, direction: 1), .unchanged)
            XCTAssertEqual(ReferenceMetricTrend.resolve(card: card, direction: -1), .unchanged)
        }
    }
}
