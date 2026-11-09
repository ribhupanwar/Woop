import Foundation
import StrandAnalytics

/// Lossless subset shared with the Apple preview adapter. Unsupported phase order is refused,
/// never flattened into work steps or silently removed.
struct WatchRunningPlanLayout {
    let warmup: WorkoutGuidance.Phase?
    let intervals: [WorkoutGuidance.Phase]
    let cooldown: WorkoutGuidance.Phase?

    init?(phases: [WorkoutGuidance.Phase]) {
        guard WorkoutGuidance(phases: phases).isValid else { return nil }
        var steps = phases
        warmup = steps.first?.kind == .warmup ? steps.removeFirst() : nil
        cooldown = steps.last?.kind == .cooldown ? steps.removeLast() : nil
        guard !steps.isEmpty, steps.allSatisfy({ $0.kind == .work || $0.kind == .recovery }) else { return nil }
        intervals = steps
    }
}

#if os(iOS) && canImport(WorkoutKit)
import SwiftUI
import HealthKit
import WorkoutKit
import StrandDesign

/// Apple's opt-in preview owns the Watch add/permission flow; showing this button schedules nothing.
struct WatchRunningPlanPreviewButton: View {
    let phases: [WorkoutGuidance.Phase]
    let gpsEnabled: Bool
    @State private var presented = false
    @State private var planId = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: NoopMetrics.space2) {
            if let plan = Self.makePlan(phases: phases, gpsEnabled: gpsEnabled, id: planId) {
                Button("Preview for Apple Watch", systemImage: "applewatch") {
                    planId = UUID()
                    presented = true
                }
                    .disabled(!WorkoutScheduler.isSupported)
                    .workoutPreview(plan, isPresented: $presented)
                    .accessibilityIdentifier("activity.running.appleWatchPreview")
                Text("Review and add with Apple's controls. A supported paired Watch is required. Recording in Apple Workout uses that app's sensor setup; avoid recording the same run twice.")
                    .font(StrandFont.footnote).foregroundStyle(StrandPalette.textSecondary)
            } else {
                Text("Watch preview needs work or recovery steps, with at most one warm-up at the start and one cooldown at the end. Distance steps need GPS enabled.")
                    .font(StrandFont.footnote).foregroundStyle(StrandPalette.textSecondary)
            }
        }
    }

    static func makePlan(phases: [WorkoutGuidance.Phase], gpsEnabled: Bool, id: UUID) -> WorkoutPlan? {
        guard let layout = WatchRunningPlanLayout(phases: phases),
              gpsEnabled || !WorkoutGuidance(phases: phases).requiresGPS,
              CustomWorkout.supportsActivity(.running) else { return nil }
        let location: HKWorkoutSessionLocationType = gpsEnabled ? .outdoor : .indoor
        func goal(_ phase: WorkoutGuidance.Phase) -> WorkoutGoal {
            if let seconds = phase.seconds { return .time(seconds, .seconds) }
            // The validated source phase has exactly one finite positive goal.
            return .distance(phase.meters!, .meters)
        }
        guard phases.allSatisfy({ CustomWorkout.supportsGoal(goal($0), activity: .running, location: location) }) else { return nil }
        let warmup = layout.warmup.map { WorkoutStep(goal: goal($0)) }
        let cooldown = layout.cooldown.map { WorkoutStep(goal: goal($0)) }
        let steps = layout.intervals.map {
            IntervalStep($0.kind == .recovery ? .recovery : .work, goal: goal($0))
        }
        let workout = CustomWorkout(activity: .running, location: location, displayName: "Woop Run",
                                    warmup: warmup, blocks: [IntervalBlock(steps: steps, iterations: 1)], cooldown: cooldown)
        return WorkoutPlan(.custom(workout), id: id)
    }
}
#endif
