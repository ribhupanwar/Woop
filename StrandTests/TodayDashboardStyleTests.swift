import XCTest
@testable import Strand

final class TodayDashboardStyleTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suite = "TodayDashboardStyleTests.\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    func testFreshInstallDefaultsToOverview() {
        let defaults = makeDefaults()
        TodayDashboardStyle.migrateLegacyBoolIfNeeded(in: defaults)
        XCTAssertEqual(defaults.string(forKey: TodayDashboardStyle.storageKey), TodayDashboardStyle.overview.rawValue)
    }

    func testLegacyLiquidChoiceIsPreserved() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "noop.liquidTodayEnabled")
        TodayDashboardStyle.migrateLegacyBoolIfNeeded(in: defaults)
        XCTAssertEqual(defaults.string(forKey: TodayDashboardStyle.storageKey), TodayDashboardStyle.liquid.rawValue)
    }

    func testLegacyClassicChoiceIsPreserved() {
        let defaults = makeDefaults()
        defaults.set(false, forKey: "noop.liquidTodayEnabled")
        TodayDashboardStyle.migrateLegacyBoolIfNeeded(in: defaults)
        XCTAssertEqual(defaults.string(forKey: TodayDashboardStyle.storageKey), TodayDashboardStyle.classic.rawValue)
    }

    func testExistingDashboardSelectionAlwaysWins() {
        let defaults = makeDefaults()
        defaults.set(TodayDashboardStyle.trends.rawValue, forKey: TodayDashboardStyle.storageKey)
        defaults.set(true, forKey: "noop.liquidTodayEnabled")
        TodayDashboardStyle.migrateLegacyBoolIfNeeded(in: defaults)
        XCTAssertEqual(defaults.string(forKey: TodayDashboardStyle.storageKey), TodayDashboardStyle.trends.rawValue)
    }
}
