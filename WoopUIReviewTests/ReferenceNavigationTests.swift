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
        reveal("woop.home.quickActions").tap()
        XCTAssertTrue(app.staticTexts["Start workout"].waitForExistence(timeout: 5),
                      "the floating action must reach the existing recording entry point")
        app.staticTexts["Start workout"].tap()
        XCTAssertTrue(app.staticTexts["Start a workout"].waitForExistence(timeout: 10),
                      "starting an activity must open the recorder picker, not Silent Guardian")
        capture("empty-start-activity")
    }

    func testHomeStartActivityOpensRecorder() {
        launch()
        let start = reveal("woop.home.startActivity")
        capture("home-start-activity-contrast")
        start.tap()
        XCTAssertTrue(app.staticTexts["Start a workout"].waitForExistence(timeout: 10))
    }

    func testCaptureEmptyReferenceScreens() {
        for tab in ["home", "health", "activity", "more"] {
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

    func testHomeMonitorRoutes() {
        launch()
        reveal("woop.home.healthMonitor").tap()
        XCTAssertTrue(app.navigationBars["HEALTH MONITOR"].waitForExistence(timeout: 10))
        capture("health-monitor-grid")
        launch()
        reveal("woop.home.stressMonitor").tap()
        XCTAssertTrue(app.navigationBars["STRESS MONITOR"].waitForExistence(timeout: 10))
        capture("stress-monitor-gauge")
    }

    func testCaptureHomeScrollSections() {
        launch()
        capture("home-top")
        for index in 1...4 {
            app.swipeUp()
            capture("home-scroll-\(index)")
        }
    }

    private func reveal(_ identifier: String) -> XCUIElement {
        let button = app.buttons[identifier]
        for _ in 0..<8 {
            if button.exists && button.isHittable { return button }
            app.swipeUp()
        }
        XCTAssertTrue(button.exists && button.isHittable, "Missing reachable control: \(identifier)")
        return button
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
