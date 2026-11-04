import Foundation

/// KDM biological-age estimate using the published NHANES-derived BACalc parameter set.
///
/// This is a population-calibrated estimate, not a diagnosis or a universally accepted biological-age
/// standard. Every biomarker is required: this implementation deliberately does not impute missing labs.
/// Units are fixed to the reference equation. CRP is entered as mg/L and transformed with natural log.
public enum BiologicalAgeKDM {
    public static let modelName = "KDM · NHANES/BACalc 13-marker"
    public static let biomarkerCount = 13

    public struct Biomarkers: Equatable, Sendable {
        public let albuminGdL: Double
        public let alkalinePhosphataseUL: Double
        public let bloodUreaNitrogenMgDL: Double
        public let creatinineMgDL: Double
        public let hemoglobinA1cPct: Double
        public let crpMgL: Double
        public let lymphocytesPct: Double
        public let meanCorpuscularVolumeFL: Double
        public let glucoseMgDL: Double
        public let redCellDistributionWidthPct: Double
        public let totalCholesterolMgDL: Double
        public let systolicBloodPressureMmHg: Double
        public let whiteBloodCellCount10e3PerUL: Double

        public init(albuminGdL: Double, alkalinePhosphataseUL: Double, bloodUreaNitrogenMgDL: Double,
                    creatinineMgDL: Double, hemoglobinA1cPct: Double, crpMgL: Double,
                    lymphocytesPct: Double, meanCorpuscularVolumeFL: Double, glucoseMgDL: Double,
                    redCellDistributionWidthPct: Double, totalCholesterolMgDL: Double,
                    systolicBloodPressureMmHg: Double, whiteBloodCellCount10e3PerUL: Double) {
            self.albuminGdL = albuminGdL
            self.alkalinePhosphataseUL = alkalinePhosphataseUL
            self.bloodUreaNitrogenMgDL = bloodUreaNitrogenMgDL
            self.creatinineMgDL = creatinineMgDL
            self.hemoglobinA1cPct = hemoglobinA1cPct
            self.crpMgL = crpMgL
            self.lymphocytesPct = lymphocytesPct
            self.meanCorpuscularVolumeFL = meanCorpuscularVolumeFL
            self.glucoseMgDL = glucoseMgDL
            self.redCellDistributionWidthPct = redCellDistributionWidthPct
            self.totalCholesterolMgDL = totalCholesterolMgDL
            self.systolicBloodPressureMmHg = systolicBloodPressureMmHg
            self.whiteBloodCellCount10e3PerUL = whiteBloodCellCount10e3PerUL
        }

        fileprivate var values: [Double] {
            [albuminGdL, alkalinePhosphataseUL, bloodUreaNitrogenMgDL, creatinineMgDL,
             hemoglobinA1cPct, log(crpMgL), lymphocytesPct, meanCorpuscularVolumeFL,
             glucoseMgDL, redCellDistributionWidthPct, totalCholesterolMgDL,
             systolicBloodPressureMmHg, whiteBloodCellCount10e3PerUL]
        }

        public var hasPlausiblePositiveInputs: Bool {
            let raw = [albuminGdL, alkalinePhosphataseUL, bloodUreaNitrogenMgDL, creatinineMgDL,
                       hemoglobinA1cPct, crpMgL, lymphocytesPct, meanCorpuscularVolumeFL,
                       glucoseMgDL, redCellDistributionWidthPct, totalCholesterolMgDL,
                       systolicBloodPressureMmHg, whiteBloodCellCount10e3PerUL]
            return raw.allSatisfy { $0.isFinite && $0 > 0 }
                && (0...100).contains(lymphocytesPct)
                && (0...100).contains(hemoglobinA1cPct)
                && (0...100).contains(redCellDistributionWidthPct)
                && (50...250).contains(systolicBloodPressureMmHg)
        }
    }

    public struct Result: Equatable, Sendable {
        public let biologicalAge: Double
        public let chronologicalAge: Double
        public var ageAcceleration: Double { biologicalAge - chronologicalAge }
        public let biomarkersUsed: Int
        public let model: String
    }

    private struct Parameter {
        let k: Double
        let q: Double
        let weight: Double
    }

    // Table 1 and equations 27–28, Liu et al., JMIR Form Res 2026;10:e95321.
    // Fixed NHANES 1999–2010 calibration; units follow the published parameterization.
    private static let parameters: [Parameter] = [
        .init(k: -0.002527, q: 4.348, weight: 0.00005521),       // albumin, g/dL
        .init(k: 0.1383, q: 64.15, weight: 0.00004087),         // ALP, U/L
        .init(k: 0.1131, q: 7.822, weight: 0.0005984),          // BUN, mg/dL
        .init(k: 0.003724, q: 0.6939, weight: 0.0002474),       // creatinine, mg/dL
        .init(k: 0.01395, q: 4.946, weight: 0.0003087),        // HbA1c, %
        .init(k: 0.0006252, q: 0.2306, weight: 0.000006166),    // ln(CRP mg/L)
        .init(k: -0.04888, q: 32.63, weight: 0.00003644),      // lymphocytes, %
        .init(k: 0.05397, q: 86.79, weight: 0.0001006),        // MCV, fL
        .init(k: 0.3578, q: 80.71, weight: 0.0001787),         // glucose, mg/dL
        .init(k: 0.01022, q: 12.62, weight: 0.00008125),       // RDW, %
        .init(k: 0.183, q: 186.3, weight: 0.00002180),         // total cholesterol, mg/dL
        .init(k: 0.4536, q: 102.0, weight: 0.0007404),         // systolic BP, mmHg
        .init(k: -0.009997, q: 7.715, weight: 0.00002469)      // WBC, 10^3/uL
    ]

    /// Returns nil rather than inventing an age when age or any required biomarker is missing/invalid.
    public static func estimate(chronologicalAge: Double, biomarkers: Biomarkers) -> Result? {
        guard chronologicalAge.isFinite, (18...110).contains(chronologicalAge),
              biomarkers.hasPlausiblePositiveInputs else { return nil }
        let values = biomarkers.values
        guard values.count == parameters.count,
              values.allSatisfy(\.isFinite) else { return nil }

        var numerator = 0.0
        var totalWeight = 0.0
        for (value, parameter) in zip(values, parameters) {
            guard abs(parameter.k) > 1e-12 else { return nil }
            let equivalentAge = (value - parameter.q) / parameter.k
            numerator += parameter.weight * equivalentAge
            totalWeight += parameter.weight
        }
        guard totalWeight > 0, numerator.isFinite else { return nil }

        let biomarkerAge = numerator / totalWeight
        // Published BACalc equation 28: NHANES calibration correction anchoring noisy estimates to CA.
        let corrected = ((biomarkerAge * 0.0024406) + (chronologicalAge / 397.1))
            / (0.0024406 + (1.0 / 397.1))
        guard corrected.isFinite, (0...130).contains(corrected) else { return nil }
        return Result(biologicalAge: corrected, chronologicalAge: chronologicalAge,
                      biomarkersUsed: biomarkerCount, model: modelName)
    }
}
