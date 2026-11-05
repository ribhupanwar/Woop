import Foundation
import WhoopProtocol

/// Wrap-aware step derivation from the strap's cumulative `step_motion_counter@57`, shared by the daily
/// total (`AnalyticsEngine.analyzeDay`) and any windowed total (a manual workout's `[start, end]`, #398).
///
/// `step_motion_counter@57` is a CUMULATIVE u16 motion counter: it climbs for both locomotion and some
/// non-step wrist motion, and wraps at 65536. On classed WHOOP 5/MG records, the increment ending at each
/// sample is counted only when the strap labels that sample walk (1) or run (2); still (0) and unknown are
/// rejected. A wholly unclassed legacy window retains the old counter-only estimate so pre-migration history
/// remains readable. The caller applies its per-user `stepTicksPerStep` calibration afterwards. The result is
/// still an estimate, not cloud/clinical parity.
///
/// Kept byte-for-byte in lockstep with the Kotlin twin `StepsCounter.stepsInWindow`.
public enum StepsCounter {
    private static let locomotionActivityClasses: Set<Int> = [1, 2]

    static func hasActivityClasses(_ samples: [StepSample]) -> Bool {
        samples.contains { $0.activityClass != nil }
    }

    /// Kotlin twin: `StepsCounter.shouldCountDelta`.
    static func shouldCountDelta(activityClass: Int?, hasActivityClasses: Bool) -> Bool {
        !hasActivityClasses || activityClass.map(locomotionActivityClasses.contains) == true
    }

    /// Absolute reboot/wrap guard, independent from the per-second plausibility gate below.
    public static let maxStepDelta = 512
    public static let maxTicksPerSecond = 4

    /// Kotlin twin: `StepsCounter.isPlausibleDelta`.
    static func isPlausibleDelta(previousTs: Int, currentTs: Int, delta: Int) -> Bool {
        guard delta >= 1, delta < maxStepDelta else { return false }
        let elapsed = currentTs - previousTs
        guard elapsed > 0 else { return false }
        let rateAllowance = elapsed >= maxStepDelta / maxTicksPerSecond
            ? maxStepDelta - 1
            : elapsed * maxTicksPerSecond
        return delta <= rateAllowance
    }

    /// Raw wrap-aware locomotion-tick total across `samples`. When any sample carries `activityClass`, each
    /// positive increment is attributed to the later sample and retained only for walk/run. When the whole
    /// window is legacy-unclassed, all valid increments retain the historical counter-only fallback. Sorts
    /// by `ts` internally and returns `nil` for fewer than two samples or no retained movement.
    public static func stepsInWindow(_ samples: [StepSample]) -> Int? {
        let sorted = samples.sorted { $0.ts < $1.ts }
        if sorted.count < 2 { return nil }
        let hasActivityClasses = hasActivityClasses(sorted)
        var total = 0
        for i in 1..<sorted.count {
            let delta = (sorted[i].counter - sorted[i - 1].counter) & 0xFFFF  // wrap-aware u16 increment
            let isLocomotion = shouldCountDelta(
                activityClass: sorted[i].activityClass,
                hasActivityClasses: hasActivityClasses)
            if isLocomotion && isPlausibleDelta(
                previousTs: sorted[i - 1].ts, currentTs: sorted[i].ts, delta: delta) {
                total += delta
            }
        }
        return total > 0 ? total : nil
    }

    
    /// Counter ticks attributable to the exact workout interval. The surrounding samples are required:
    /// one before the start and one after the end let us prorate the boundary intervals instead of
    /// assigning every tick since the previous minute to the workout. Daily totals keep using the
    /// unbounded overload above.
    public static func stepsInWindow(_ samples: [StepSample], from startTs: Int, to endTs: Int) -> Int? {
        guard endTs > startTs else { return nil }
        let sorted = samples.sorted { $0.ts < $1.ts }
        guard sorted.count >= 2 else { return nil }
        let classed = hasActivityClasses(sorted)
        var totalTicks = 0.0
        for index in 1..<sorted.count {
            let previous = sorted[index - 1]
            let current = sorted[index]
            let elapsed = current.ts - previous.ts
            guard elapsed > 0 else { continue }
            let overlap = min(endTs, current.ts) - max(startTs, previous.ts)
            guard overlap > 0 else { continue }
            // If the interval crosses the workout end, use the last in-window sample's class;
            // the first sample after finishing may already be labelled still.
            let activityClass = current.ts > endTs ? previous.activityClass : current.activityClass
            guard shouldCountDelta(activityClass: activityClass, hasActivityClasses: classed) else { continue }
            let delta = (current.counter - previous.counter) & 0xFFFF
            guard isPlausibleDelta(previousTs: previous.ts, currentTs: current.ts, delta: delta) else {
                continue
            }
            // A single counter interval spanning the entire workout has no in-window class evidence.
            if previous.ts < startTs && current.ts > endTs { continue }
            totalTicks += Double(delta) * Double(overlap) / Double(elapsed)
        }
        let rounded = Int(totalTicks.rounded())
        return rounded > 0 ? rounded : nil
    }
}\n}
