import XCTest
@testable import Strand

final class TodayActivityTimelineTests: XCTestCase {
    func testActivityIconsCoverRunWalkDanceAndSleep() {
        XCTAssertEqual(TodayView.activitySymbol(for: "Running"), "figure.run")
        XCTAssertEqual(TodayView.activitySymbol(for: "Walking"), "figure.walk")
        XCTAssertEqual(TodayView.activitySymbol(for: "Dance"), "figure.dance")
        XCTAssertEqual(TodayView.activitySymbol(for: "Sleep"), "moon.zzz.fill")
    }

    func testActivityDurationUsesHoursAndMinutes() {
        XCTAssertEqual(TodayView.activityDurationLabel(5 * 60), "5m")
        XCTAssertEqual(TodayView.activityDurationLabel(90 * 60), "1h 30m")
        XCTAssertEqual(TodayView.activityDurationLabel(0), "—")
    }

    func testEstimatedDistanceIsExplicitlyMarked() {
        let measured = TodayView.activityDistanceLabel(5_000, estimated: false, system: .metric)
        let estimated = TodayView.activityDistanceLabel(5_000, estimated: true, system: .metric)
        XCTAssertFalse(measured.hasPrefix("~"))
        XCTAssertTrue(estimated.hasPrefix("~"))
    }

    func testMissingDistanceIsNotRenderedAsAnEmptyField() {
        XCTAssertEqual(TodayView.activityDistanceLabel(nil, estimated: false, system: .metric),
                       "Distance unavailable")
    }
}
