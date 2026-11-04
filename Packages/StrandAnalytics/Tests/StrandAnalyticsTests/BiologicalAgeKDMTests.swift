import XCTest
@testable import StrandAnalytics

final class BiologicalAgeKDMTests: XCTestCase {
    func testNHANESReferenceAgeIsRecoveredWhenEveryMarkerMatchesAge50RegressionLine() throws {
        // Each value is q + k × 50 from the published 13-marker NHANES calibration.
        let b = BiologicalAgeKDM.Biomarkers(
            albuminGdL: 4.22165,
            alkalinePhosphataseUL: 71.065,
            bloodUreaNitrogenMgDL: 13.477,
            creatinineMgDL: 0.8801,
            hemoglobinA1cPct: 5.6435,
            crpMgL: exp(0.26186),
            lymphocytesPct: 30.186,
            meanCorpuscularVolumeFL: 89.4885,
            glucoseMgDL: 98.6,
            redCellDistributionWidthPct: 13.13,
            totalCholesterolMgDL: 195.45,
            systolicBloodPressureMmHg: 124.68,
            whiteBloodCellCount10e3PerUL: 7.215
        )
        let result = try XCTUnwrap(BiologicalAgeKDM.estimate(chronologicalAge: 50, biomarkers: b))
        XCTAssertEqual(result.biologicalAge, 50, accuracy: 0.02)
        XCTAssertEqual(result.ageAcceleration, 0, accuracy: 0.02)
        XCTAssertEqual(result.biomarkersUsed, 13)
    }

    func testMissingOrInvalidRequiredBiomarkerDoesNotProduceAnAge() {
        let b = BiologicalAgeKDM.Biomarkers(
            albuminGdL: 4.2, alkalinePhosphataseUL: 70, bloodUreaNitrogenMgDL: 12,
            creatinineMgDL: 0.9, hemoglobinA1cPct: 5.4, crpMgL: 0,
            lymphocytesPct: 30, meanCorpuscularVolumeFL: 90, glucoseMgDL: 95,
            redCellDistributionWidthPct: 13, totalCholesterolMgDL: 180,
            systolicBloodPressureMmHg: 120, whiteBloodCellCount10e3PerUL: 6
        )
        XCTAssertNil(BiologicalAgeKDM.estimate(chronologicalAge: 40, biomarkers: b))
        XCTAssertNil(BiologicalAgeKDM.estimate(chronologicalAge: 0, biomarkers: b))
    }

    func testResultKeepsChronologicalAgeAndBiologicalAccelerationSeparate() throws {
        let b = BiologicalAgeKDM.Biomarkers(
            albuminGdL: 4.1, alkalinePhosphataseUL: 75, bloodUreaNitrogenMgDL: 14,
            creatinineMgDL: 0.95, hemoglobinA1cPct: 5.7, crpMgL: 2.0,
            lymphocytesPct: 28, meanCorpuscularVolumeFL: 91, glucoseMgDL: 102,
            redCellDistributionWidthPct: 13.4, totalCholesterolMgDL: 190,
            systolicBloodPressureMmHg: 128, whiteBloodCellCount10e3PerUL: 7
        )
        let result = try XCTUnwrap(BiologicalAgeKDM.estimate(chronologicalAge: 42, biomarkers: b))
        XCTAssertEqual(result.chronologicalAge, 42)
        XCTAssertTrue(result.biologicalAge.isFinite)
        XCTAssertEqual(result.ageAcceleration, result.biologicalAge - 42, accuracy: 1e-9)
    }
}
