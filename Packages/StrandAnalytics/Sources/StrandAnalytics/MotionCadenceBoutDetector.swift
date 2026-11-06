import Foundation

/// One non-overlapping minute summarized from a 100 Hz WHOOP 5.0 IMU window.
/// cadenceHz is the dominant gait rhythm; rhythmStrength is normalized autocorrelation confidence.
public struct MotionCadenceMinute: Equatable, Sendable {
    public let startTs: Int
    public let cadenceHz: Double?
    public let rhythmStrength: Double
    public let sampleCount: Int
    public let averageBpm: Int?

    public init(startTs: Int, cadenceHz: Double?, rhythmStrength: Double,
                sampleCount: Int, averageBpm: Int? = nil) {
        self.startTs = startTs
        self.cadenceHz = cadenceHz
        self.rhythmStrength = rhythmStrength
        self.sampleCount = sampleCount
        self.averageBpm = averageBpm
    }
}

public enum MotionCadenceBoutDetector {
    public static let minimumDurationMinutes = 10
    public static let minimumQualifyingShare = 0.8
    public static let maximumGapMinutes = 2
    public static let minimumCadenceHz = 1.2
    public static let maximumCadenceHz = 3.5
    public static let minimumRhythmStrength = 0.20
    public static let minimumSamplesPerMinute = 3_000

    public enum Kind: String, Sendable { case walk, run }

    /// Cadence alone is not enough to name a sport: gym/strength movements can create a fast,
    /// rhythmic wrist signal too. Only label a cadence bout as walking/running when GPS confirms
    /// meaningful locomotion. Without that evidence, the caller should use a neutral "Workout" label.
    public static func classifyLocomotion(gpsDistanceM: Double?, durationSeconds: Int) -> Kind? {
        guard durationSeconds > 0, let distance = gpsDistanceM,
              distance.isFinite, distance >= 200 else { return nil }
        let speedMps = distance / Double(durationSeconds)
        guard speedMps >= 0.8 else { return nil }
        return speedMps >= 2.2 ? .run : .walk
    }

    /// HR is supporting context only. Missing or low HR never vetoes a cadence-confirmed bout.
    public struct Candidate: Equatable, Sendable {
        public let startTs: Int
        public let endTs: Int
        public let kind: Kind
        public let medianCadenceHz: Double
        public let meanRhythmStrength: Double
        public let averageBpm: Int?
        public let hrElevationBpm: Int?
        public let durationMinutes: Int
    }

    public static func detect(_ input: [MotionCadenceMinute], restingBpm: Int? = nil) -> [Candidate] {
        let rows = input.sorted { $0.startTs < $1.startTs }
        let valid = rows.map { row in
            row.sampleCount >= minimumSamplesPerMinute
                && row.rhythmStrength >= minimumRhythmStrength
                && (row.cadenceHz.map { $0 >= minimumCadenceHz && $0 <= maximumCadenceHz } ?? false)
        }
        var results: [Candidate] = []
        var i = 0
        while i < rows.count {
            guard valid[i] else { i += 1; continue }
            let start = i
            var lastGood = i
            var good = 1
            var gap = 0
            var j = i + 1
            while j < rows.count {
                let delta = rows[j].startTs - rows[j - 1].startTs
                if delta > 60 * (maximumGapMinutes + 1) { break }
                if valid[j] {
                    good += 1; lastGood = j; gap = 0
                } else {
                    gap += 1
                    if gap > maximumGapMinutes { break }
                }
                j += 1
            }
            let spanMinutes = (rows[lastGood].startTs - rows[start].startTs) / 60 + 1
            if spanMinutes >= minimumDurationMinutes,
               Double(good) / Double(spanMinutes) >= minimumQualifyingShare {
                let bout = Array(rows[start...lastGood]).filter { row in
                    row.sampleCount >= minimumSamplesPerMinute && row.rhythmStrength >= minimumRhythmStrength
                        && (row.cadenceHz.map { $0 >= minimumCadenceHz && $0 <= maximumCadenceHz } ?? false)
                }
                let cadences = bout.compactMap(\.cadenceHz).sorted()
                let median = cadences[cadences.count / 2]
                let strengths = bout.map(\.rhythmStrength)
                let hr = bout.compactMap(\.averageBpm)
                let avgHR = hr.isEmpty ? nil : Int((Double(hr.reduce(0, +)) / Double(hr.count)).rounded())
                results.append(Candidate(
                    startTs: rows[start].startTs, endTs: rows[lastGood].startTs + 60,
                    kind: median >= 2.5 ? .run : .walk,
                    medianCadenceHz: median,
                    meanRhythmStrength: strengths.reduce(0, +) / Double(strengths.count),
                    averageBpm: avgHR,
                    hrElevationBpm: (avgHR != nil && restingBpm != nil) ? avgHR! - restingBpm! : nil,
                    durationMinutes: spanMinutes
                ))
            }
            i = max(i + 1, lastGood + 1)
        }
        return results
    }
}
