import XCTest
@testable import Strand

@MainActor
final class DashboardTrendMeaningTests: XCTestCase {
    func testHRVAndRestingHeartRateHaveOppositeFavorableDirections() {
        XCTAssertEqual(DashboardTrendMeaning.resolve(card: .hrv, direction: 1), .favorable)
        XCTAssertEqual(DashboardTrendMeaning.resolve(card: .hrv, direction: -1), .unfavorable)
        XCTAssertEqual(DashboardTrendMeaning.resolve(card: .restingHr, direction: -1), .favorable)
        XCTAssertEqual(DashboardTrendMeaning.resolve(card: .restingHr, direction: 1), .unfavorable)
    }

    func testStepsFollowActivityDirectionAndUnchangedValuesStayNeutral() {
        XCTAssertEqual(DashboardTrendMeaning.resolve(card: .steps, direction: 1), .favorable)
        XCTAssertEqual(DashboardTrendMeaning.resolve(card: .steps, direction: -1), .unfavorable)
        for card in DashboardCard.allCases {
            XCTAssertEqual(DashboardTrendMeaning.resolve(card: card, direction: 0), .neutral)
        }
    }

    func testContextDependentMetricsDoNotInventFavorableDirections() {
        let cards: [DashboardCard] = [.calories, .weight, .respiratory, .skinTemp, .bloodOxygen, .hydration]
        for card in cards {
            XCTAssertEqual(DashboardTrendMeaning.resolve(card: card, direction: 1), .neutral)
            XCTAssertEqual(DashboardTrendMeaning.resolve(card: card, direction: -1), .neutral)
        }
    }
}
