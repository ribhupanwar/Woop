import XCTest
import StrandAnalytics
import WhoopStore
@testable import Strand

final class RecordedBloodPressureTests: XCTestCase {
    private func row(_ key: String, value: Double, timestamp: Int, source: String = "manual") -> LabMarkerRow {
        .init(id: "\(key)-\(timestamp)-\(source)", deviceId: "band", markerKey: key, category: "bloodPressure",
              day: "2026-11-08", takenAt: timestamp, value: value, valueText: nil, unit: "mmHg",
              source: source, note: nil, referenceText: nil)
    }
    func testDifferentDatesOrSourcesCannotFormOnePressureReading() {
        let sys = row(LabBookProjection.bpSystolicKey, value: 120, timestamp: 100)
        XCTAssertNil(RecordedBloodPressure.latest([sys, row(LabBookProjection.bpDiastolicKey, value: 80, timestamp: 200)]))
        XCTAssertNil(RecordedBloodPressure.latest([sys, row(LabBookProjection.bpDiastolicKey, value: 80, timestamp: 100, source: "import")]))
    }
    func testLatestCompletePairWinsOverNewerIncompleteReading() throws {
        let rows = [row(LabBookProjection.bpSystolicKey, value: 120, timestamp: 100),
                    row(LabBookProjection.bpDiastolicKey, value: 80, timestamp: 100),
                    row(LabBookProjection.bpSystolicKey, value: 125, timestamp: 200)]
        let result = try XCTUnwrap(RecordedBloodPressure.latest(rows))
        XCTAssertEqual(result.systolic, 120)
        XCTAssertEqual(result.diastolic, 80)
        XCTAssertEqual(result.takenAt, 100)
    }
}
