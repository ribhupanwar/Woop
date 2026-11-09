import XCTest

/// Uses an empty simulator store, never synthetic health values. DEBUG-only preview arguments bypass
/// first-run gates; the production app retains onboarding, consent and Health permission checks.
final class ReferenceNavigationTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(tab: String = "home") {
        app.terminate()
        app.launchArguments = ["--ui-preview", "--demo-tab", tab]
        app.launch()
        XCTAssertTrue(app.buttons["woop.tab.0"].waitForExistence(timeout: 30))
    }

    func testReferenceTabsSwitchAndHomeQuickActionsOpen() {
        launch()
        XCTAssertEqual(app.tabBars.buttons.count, 0, "the native bar must not duplicate the reference bar")
        XCTAssertFalse(app.buttons["woop.tab.1"].exists, "Today is consolidated into Home")
        for tag in [2, 4, 3, 0] {
            let button = app.buttons["woop.tab.\(tag)"]
            XCTAssertTrue(button.exists)
            button.tap()
            let selected = NSPredicate(format: "selected == true")
            expectation(for: selected, evaluatedWith: button)
            waitForExpectations(timeout: 5)
        }
        let quickActions = app.buttons["woop.home.quickActions"]
        XCTAssertTrue(quickActions.isHittable)
        XCTAssertLessThanOrEqual(quickActions.frame.maxY, app.buttons["woop.tab.0"].frame.minY - 8,
                                 "the floating button must stay above navigation and remain tappable")
        quickActions.tap()
        let startWorkout = app.buttons["woop.quickActions.startWorkout"]
        XCTAssertTrue(startWorkout.waitForExistence(timeout: 5),
                      "the floating action must reach the existing recording entry point")
        startWorkout.tap()
        XCTAssertTrue(app.staticTexts["Start a workout"].waitForExistence(timeout: 10),
                      "starting an activity must open the recorder picker, not Silent Guardian")
        capture("empty-start-activity")
    }

    func testHomeStartActivityOpensRecorder() {
        launch()
        let start = app.buttons["woop.home.startActivity"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        for _ in 0..<3 where !start.isHittable { app.swipeUp() }
        XCTAssertTrue(start.isHittable)
        capture("home-start-activity-contrast")
        start.tap()
        XCTAssertTrue(app.staticTexts["Start a workout"].waitForExistence(timeout: 10))
    }

    func testCaptureEmptyReferenceScreens() {
        for tab in ["home", "activity", "healthspan", "more"] {
            launch(tab: tab)
            capture("empty-\(tab)")
        }
        for screen in ["recovery", "sleep", "strain", "health", "stress"] {
            app.terminate()
            app.launchArguments = ["--ui-preview", "--demo-screen", screen]
            app.launch()
            capture("empty-\(screen)")
        }
    }

    func testHealthspanECGEntryOpensExistingCaptureWithoutStartingAReading() {
        launch(tab: "healthspan")
        let ecg = app.buttons["woop.healthspan.measureECG"]
        XCTAssertTrue(ecg.waitForExistence(timeout: 10))
        ecg.tap()
        XCTAssertTrue(app.navigationBars["ECG reading"].waitForExistence(timeout: 10))
        capture("ecg-entry-no-measurement")
    }

    func testHomeMonitorsOpenTheirDetailScreens() {
        launch()
        let health = app.buttons["woop.home.healthMonitor"]
        XCTAssertTrue(health.waitForExistence(timeout: 10))
        health.tap()
        XCTAssertTrue(app.navigationBars["Health Monitor"].waitForExistence(timeout: 10))
        launch()
        app.buttons["woop.home.stressMonitor"].tap()
        XCTAssertTrue(app.navigationBars["Stress Monitor"].waitForExistence(timeout: 10))
    }

    func testHealthIsSecondAndTonightSleepOpensPlanner() {
        launch()
        let home = app.buttons["woop.tab.0"]
        let health = app.buttons["woop.tab.3"]
        let activity = app.buttons["woop.tab.2"]
        XCTAssertLessThan(home.frame.midX, health.frame.midX)
        XCTAssertLessThan(health.frame.midX, activity.frame.midX)
        let tonight = app.buttons["woop.home.tonightSleep"]
        for _ in 0..<6 {
            if tonight.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(tonight.isHittable)
        tonight.tap()
        XCTAssertTrue(app.navigationBars["Sleep Planner"].waitForExistence(timeout: 10))
        capture("empty-sleep-planner")
    }

    private func capture(_ name: String) {
        // Allow the empty-store loading state to settle; no sensor data is generated for screenshots.
        Thread.sleep(forTimeInterval: 3)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
