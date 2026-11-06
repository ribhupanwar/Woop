import Foundation

/// Patent-inspired VO₂max model selection and calibration.
///
/// This is an independently implemented state machine, not WHOOP's proprietary trained estimator.
/// It deliberately accepts candidate model outputs rather than inventing a passive regression.
public enum VO2MaxModelSelector {
    public static let gpsLookbackDays = 90
    public static let calibrationPairingDays = 7

    public enum Mode: String, Equatable, Sendable {
        case passive
        case gpsAugmented
        case passivePlusGPS
        case labCalibrated
    }

    public struct DatedValue: Equatable, Sendable {
        public let day: String
        public let value: Double
        public init(day: String, value: Double) {
            self.day = day
            self.value = value
        }
    }

    public struct Input: Equatable, Sendable {
        public let today: String
        /// Output from a separately validated passive model, if one exists.
        public let passive: DatedValue?
        /// Output from the independent GPS/HR running estimator, if a qualifying run exists.
        public let gps: DatedValue?
        /// Passive model output nearest the GPS run date; used only to derive a GPS continuity offset.
        public let passiveAtGPS: DatedValue?
        /// A user-entered clinical gas-exchange measurement.
        public let lab: DatedValue?
        /// Passive model output near the lab test date; used only to derive lab calibration.
        public let passiveAtLab: DatedValue?

        public init(today: String, passive: DatedValue?, gps: DatedValue? = nil,
                    passiveAtGPS: DatedValue? = nil, lab: DatedValue? = nil,
                    passiveAtLab: DatedValue? = nil) {
            self.today = today
            self.passive = passive
            self.gps = gps
            self.passiveAtGPS = passiveAtGPS
            self.lab = lab
            self.passiveAtLab = passiveAtLab
        }
    }

    public struct Result: Equatable, Sendable {
        public let value: Double
        public let mode: Mode
        public let confidence: String
        /// Additive correction applied to the current passive estimate, when applicable.
        public let offset: Double?
        /// Date of the evidence that selected/calibrated this mode.
        public let evidenceDay: String
    }

    /// Selects the strongest eligible evidence without pretending that a candidate exists when it does not.
    public static func resolve(_ input: Input) -> Result? {
        guard validDay(input.today) != nil else { return nil }

        // A recent qualifying GPS run is the active model. The GPS candidate itself must be finite/plausible.
        if let gps = eligible(input.gps, on: input.today, maximumAgeDays: gpsLookbackDays),
           plausible(gps.value) {
            return Result(value: gps.value, mode: .gpsAugmented,
                          confidence: "GPS + measured heart-rate evidence",
                          offset: nil, evidenceDay: gps.day)
        }

        guard let passive = eligible(input.passive, on: input.today, maximumAgeDays: nil),
              plausible(passive.value) else { return nil }

        // A lab anchor is retained until replaced. It calibrates the passive model only when a paired
        // passive output exists within the disclosed one-week comparison window.
        if let lab = eligible(input.lab, on: input.today, maximumAgeDays: nil),
           plausible(lab.value),
           let baseline = nearestPair(input.passiveAtLab, to: lab.day),
           plausible(baseline.value) {
            let correction = lab.value - baseline.value
            let calibrated = passive.value + correction
            guard plausible(calibrated) else { return nil }
            return Result(value: calibrated, mode: .labCalibrated,
                          confidence: "Passive model calibrated to lab measurement",
                          offset: correction, evidenceDay: lab.day)
        }

        // When GPS evidence expires, retain the last GPS-vs-passive offset. This is a continuity
        // mechanism disclosed by the patent; it is not a fresh GPS measurement.
        if let gps = input.gps, validDay(gps.day) != nil,
           let age = daysBetween(gps.day, input.today), age > gpsLookbackDays,
           let baseline = nearestPair(input.passiveAtGPS, to: gps.day),
           plausible(gps.value), plausible(baseline.value) {
            let correction = gps.value - baseline.value
            let adjusted = passive.value + correction
            guard plausible(adjusted) else { return nil }
            return Result(value: adjusted, mode: .passivePlusGPS,
                          confidence: "Passive model with retained historical GPS offset",
                          offset: correction, evidenceDay: gps.day)
        }

        return Result(value: passive.value, mode: .passive,
                      confidence: "Passive model; no recent GPS or paired lab calibration",
                      offset: nil, evidenceDay: passive.day)
    }

    private static func nearestPair(_ value: DatedValue?, to day: String) -> DatedValue? {
        guard let value, let age = daysBetween(value.day, day), age <= calibrationPairingDays,
              plausible(value.value) else { return nil }
        return value
    }

    private static func eligible(_ value: DatedValue?, on today: String,
                                 maximumAgeDays: Int?) -> DatedValue? {
        guard let value, plausible(value.value),
              let age = daysBetween(value.day, today), age >= 0 else { return nil }
        if let maximumAgeDays, age > maximumAgeDays { return nil }
        return value
    }

    private static func plausible(_ value: Double) -> Bool {
        value.isFinite && (10...100).contains(value)
    }

    private static func validDay(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter.date(from: value)
    }

    private static func daysBetween(_ earlier: String, _ later: String) -> Int? {
        guard let a = validDay(earlier), let b = validDay(later), b >= a else { return nil }
        return Calendar(identifier: .gregorian).dateComponents([.day], from: a, to: b).day
    }
}
