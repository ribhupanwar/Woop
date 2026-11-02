import XCTest
@testable import Strand

final class TodayDashboardStyleTests: XCTestCase {
    private func makeDefaults() -> (UserDefaults, String) {
        let suite = "TodayDashboardStyleTests.\(UUID().uuidString)"
        return (UserDefaults(suiteName: suite)!, suite)
    }

    func testFreshInstallDefaultsToOverview() {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }

        TodayDashboardStyle.migrateLegacyBoolIfNeeded(in: defaults)

        XCTAssertEqual(defaults.string(forKey: TodayDashboardStyle.storageKey), TodayDashboardStyle.overview.rawValue)
    }

    func testExplicitLegacyLiquidChoiceIsPreserved() {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "noop.liquidTodayEnabled")

        TodayDashboardStyle.migrateLegacyBoolIfNeeded(in: defaults)

        XCTAssertEqual(defaults.string(forKey: TodayDashboardStyle.storageKey), TodayDashboardStyle.liquid.rawValue)
    }

    func testExplicitLegacyClassicChoiceIsPreserved() {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(false, forKey: "noop.liquidTodayEnabled")

        TodayDashboardStyle.migrateLegacyBoolIfNeeded(in: defaults)

        XCTAssertEqual(defaults.string(forKey: TodayDashboardStyle.storageKey), TodayDashboardStyle.classic.rawValue)
    }

    func testExistingFourWayChoiceIsNeverOverwritten() {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(TodayDashboardStyle.trends.rawValue, forKey: TodayDashboardStyle.storageKey)
        defaults.set(false, forKey: "noop.liquidTodayEnabled")

        TodayDashboardStyle.migrateLegacyBoolIfNeeded(in: defaults)

        XCTAssertEqual(defaults.string(forKey: TodayDashboardStyle.storageKey), TodayDashboardStyle.trends.rawValue)
    }

    func testMigrationIsIdempotentAfterFirstWrite() {
        let (defaults, suite) = makeDefaults()
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(true, forKey: "noop.liquidTodayEnabled")
        TodayDashboardStyle.migrateLegacyBoolIfNeeded(in: defaults)
        defaults.set(TodayDashboardStyle.overview.rawValue, forKey: TodayDashboardStyle.storageKey)

        TodayDashboardStyle.migrateLegacyBoolIfNeeded(in: defaults)

        XCTAssertEqual(defaults.string(forKey: TodayDashboardStyle.storageKey), TodayDashboardStyle.overview.rawValue)
    }
}
