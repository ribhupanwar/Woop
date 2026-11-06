import XCTest
@testable import StrandAnalytics

final class VO2MaxModelSelectorTests: XCTestCase {
    private func value(_ day: String, _ number: Double) -> VO2MaxModelSelector.DatedValue {
        .init(day: day, value: number)
    }

    func testPassiveIsUsedWhenNoSupplementalEvidenceExists() {
        let result = VO2MaxModelSelector.resolve(.init(
            today: "2026-11-06", passive: value("2026-11-05", 48)))
        XCTAssertEqual(result?.value, 48)
        XCTAssertEqual(result?.mode, .passive)
    }

    func testRecentGPSRunSelectsActiveModel() {
        let result = VO2MaxModelSelector.resolve(.init(
            today: "2026-11-06", passive: value("2026-11-06", 46),
            gps: value("2026-10-01", 49)))
        XCTAssertEqual(result?.value, 49)
        XCTAssertEqual(result?.mode, .gpsAugmented)
    }

    func testGPSEvidenceExpiresAfterNinetyDays() {
        let result = VO2MaxModelSelector.resolve(.init(
            today: "2026-11-06", passive: value("2026-11-06", 46),
            gps: value("2026-08-07", 50),
            passiveAtGPS: value("2026-08-07", 47)))
        XCTAssertEqual(result?.value, 49)
        XCTAssertEqual(result?.mode, .passivePlusGPS)
        XCTAssertEqual(result?.offset, 3)
    }

    func testLabMeasurementCalibratesPassiveModel() {
        let result = VO2MaxModelSelector.resolve(.init(
            today: "2026-11-06", passive: value("2026-11-06", 47),
            lab: value("2026-10-20", 52),
            passiveAtLab: value("2026-10-18", 49)))
        XCTAssertEqual(result?.value, 50)
        XCTAssertEqual(result?.mode, .labCalibrated)
        XCTAssertEqual(result?.offset, 3)
    }

    func testPairedLabCalibrationTakesPrecedenceOverGPS() {
        let result = VO2MaxModelSelector.resolve(.init(
            today: "2026-11-06", passive: value("2026-11-06", 47),
            gps: value("2026-11-01", 54),
            lab: value("2026-10-20", 52),
            passiveAtLab: value("2026-10-18", 49)))
        XCTAssertEqual(result?.value, 50)
        XCTAssertEqual(result?.mode, .labCalibrated)
    }

    func testLabCalibrationRequiresPassivePairWithinOneWeek() {
        let result = VO2MaxModelSelector.resolve(.init(
            today: "2026-11-06", passive: value("2026-11-06", 47),
            lab: value("2026-10-20", 52),
            passiveAtLab: value("2026-10-12", 49)))
        XCTAssertEqual(result?.mode, .passive)
        XCTAssertEqual(result?.value, 47)
    }

    func testFutureAndInvalidValuesAreRejected() {
        XCTAssertNil(VO2MaxModelSelector.resolve(.init(
            today: "2026-11-06", passive: value("2026-11-07", 47))))
        XCTAssertNil(VO2MaxModelSelector.resolve(.init(
            today: "2026-11-06", passive: value("2026-11-05", .nan))))
    }

    func testGPSModeExpiresAtDayNinetyOneAndUsesOffset() {
        let result = VO2MaxModelSelector.resolve(.init(
            today: "2026-11-06", passive: value("2026-11-06", 45),
            gps: value("2026-08-08", 50),
            passiveAtGPS: value("2026-08-08", 47)))
        XCTAssertEqual(result?.mode, .passivePlusGPS)
        XCTAssertEqual(result?.value, 48)
    }
}
