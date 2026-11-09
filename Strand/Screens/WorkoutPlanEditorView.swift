import SwiftUI
import StrandDesign
import StrandAnalytics

/// Only future sessions use a saved edit. A running session owns its original copy.
struct WorkoutPlanEditorView: View {
    let gpsEnabled: Bool
    @Environment(\.dismiss) private var dismiss
    @AppStorage(WorkoutGuidancePreferences.enabledKey) private var enabled = false
    @AppStorage(WorkoutGuidancePreferences.pacerKey) private var pacer = false
    @AppStorage(WorkoutGuidancePreferences.pacerMetersKey) private var pacerMeters = 5000.0
    @AppStorage(WorkoutGuidancePreferences.pacerSecondsKey) private var pacerSeconds = 1800.0
    @State private var phases: [WorkoutGuidance.Phase] = [
        .init(kind: .warmup, seconds: 300), .init(kind: .work, seconds: 180),
        .init(kind: .recovery, seconds: 120), .init(kind: .cooldown, seconds: 300)
    ]
    @State private var templates: [WorkoutGuidancePreferences.Template] = []
    @State private var templateName = ""
    @AppStorage(UnitPrefs.systemKey) private var units = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.distanceSystemKey) private var distanceUnits = ""
    private var system: UnitSystem {
        UnitPrefs.resolveDistance(system: UnitSystem(rawValue: units) ?? .metric, override: distanceUnits)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Follow a training plan", isOn: $enabled)
                    Text("The plan guides you through each phase. Recording continues when the plan ends.")
                        .foregroundStyle(.secondary)
                }
                if enabled {
                    Section {
                        ForEach(RunningProgramStarter.allCases) { starter in
                            Button(starter.title) {
                                phases = starter.phases
                            }
                        }
                        Button("6 × 400 m · GPS intervals") {
                            phases = RunningProgramStarter.distanceIntervals
                        }
                        .disabled(!gpsEnabled)
                    } header: { Text("Running starters") }
                    footer: {
                        Text("Editable examples, not a recovery-based prescription. Apply the plan, then start Running. Work and recovery phases advance automatically by active time; GPS is enabled separately when recording.")
                    }
                    if !templates.isEmpty {
                        Section("Saved templates") {
                            ForEach(templates) { template in
                                Button(template.name) {
                                    // Fresh identities reset each editor row's local target state.
                                    phases = template.phases.map { .init(kind: $0.kind, seconds: $0.seconds, meters: $0.meters) }
                                }
                                    .disabled(!gpsEnabled && template.phases.contains { $0.meters != nil })
                            }
                            .onDelete(perform: deleteTemplates)
                        }
                    }
                    Section {
                        ForEach($phases) { $phase in WorkoutPhaseEditorRow(phase: $phase, gpsEnabled: gpsEnabled) }
                            .onDelete(perform: removePhases)
                            .onMove(perform: movePhases)
                        Button("Add work and recovery", systemImage: "plus", action: addIntervals)
                            .disabled(phases.count > 62)
                    } header: { Text("Training phases") }
                    footer: { Text("Time targets use active workout time. Distance targets require GPS and wait during signal loss.") }
                    #if os(iOS) && canImport(WorkoutKit)
                    Section("Apple Watch") {
                        WatchRunningPlanPreviewButton(phases: phases, gpsEnabled: gpsEnabled)
                    }
                    #endif
                    Section("Save template") {
                        TextField("Template name", text: $templateName)
                        Button("Save template", action: saveTemplate)
                            .disabled(templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !valid)
                    }
                    if !valid {
                        Text("Add at least one valid phase. Distance targets need GPS.").foregroundStyle(StrandPalette.statusWarningForeground)
                    }
                } else if gpsEnabled {
                    Section {
                        Toggle("Pacer", isOn: $pacer)
                        if pacer {
                            Stepper(value: $pacerMeters, in: 1000...100000, step: 1000) {
                                Text(UnitFormatter.distanceFromMeters(pacerMeters, system: system))
                            }
                            Stepper(value: $pacerSeconds, in: 600...21600, step: 60) {
                                Text(WorkoutAnnouncementText.duration(Int(pacerSeconds)))
                            }
                        }
                    } footer: {
                        Text("Compares measured GPS distance with your goal time. Separate from interval plans; pauses do not count.")
                    }
                }
            }
            .tint(StrandPalette.accent)
            .navigationTitle("Training plan")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .primaryAction) { EditButton() }
                #endif
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply plan", action: applyPlan).disabled(enabled && !valid)
                }
            }
            .task { load() }
        }
    }

    private var valid: Bool {
        let plan = WorkoutGuidance(phases: phases)
        return plan.isValid && (!plan.requiresGPS || gpsEnabled)
    }

    private func load() {
        if !pacerMeters.isFinite || !(1000...100000).contains(pacerMeters) { pacerMeters = 5000 }
        if !pacerSeconds.isFinite || !(600...21600).contains(pacerSeconds) { pacerSeconds = 1800 }
        templates = WorkoutGuidancePreferences.templates()
        if let plan = WorkoutGuidancePreferences.storedPlan() { phases = plan.phases }
    }
    private func removePhases(_ indices: IndexSet) { phases.remove(atOffsets: indices) }
    private func deleteTemplates(_ indices: IndexSet) {
        let ids = Set(indices.map { templates[$0].id })
        WorkoutGuidancePreferences.deleteTemplates(ids: ids)
        templates = WorkoutGuidancePreferences.templates()
    }
    private func movePhases(_ indices: IndexSet, _ destination: Int) { phases.move(fromOffsets: indices, toOffset: destination) }
    private func addIntervals() {
        let insertAt = phases.last?.kind == .cooldown ? phases.count - 1 : phases.count
        phases.insert(contentsOf: [.init(kind: .work, seconds: 180), .init(kind: .recovery, seconds: 120)], at: insertAt)
    }
    private func saveTemplate() {
        WorkoutGuidancePreferences.saveTemplate(name: templateName, plan: WorkoutGuidance(phases: phases))
        templates = WorkoutGuidancePreferences.templates()
        templateName = ""
    }
    private func applyPlan() {
        if enabled { WorkoutGuidancePreferences.save(WorkoutGuidance(phases: phases)) }
        dismiss()
    }
}

/// Independently authored time-based examples. Selecting one edits the draft only; Apply saves it.
enum RunningProgramStarter: String, CaseIterable, Identifiable {
    case easy, intervals, tempo, longRun
    var id: String { rawValue }
    var title: String {
        switch self {
        case .easy: return String(localized: "Easy run · 35 min")
        case .intervals: return String(localized: "6 × 2 min · 38 min")
        case .tempo: return String(localized: "Tempo · 35 min")
        case .longRun: return String(localized: "Long run · 60 min")
        }
    }
    var phases: [WorkoutGuidance.Phase] {
        switch self {
        case .easy:
            return [.init(kind: .warmup, seconds: 300), .init(kind: .work, seconds: 1500), .init(kind: .cooldown, seconds: 300)]
        case .intervals:
            return [.init(kind: .warmup, seconds: 600)] + (0..<6).flatMap { _ in
                [WorkoutGuidance.Phase(kind: .work, seconds: 120), .init(kind: .recovery, seconds: 120)]
            } + [.init(kind: .cooldown, seconds: 240)]
        case .tempo:
            return [.init(kind: .warmup, seconds: 600), .init(kind: .work, seconds: 1200), .init(kind: .cooldown, seconds: 300)]
        case .longRun:
            return [.init(kind: .warmup, seconds: 600), .init(kind: .work, seconds: 2400), .init(kind: .cooldown, seconds: 600)]
        }
    }
}

extension RunningProgramStarter {
    /// Work/recovery distance goals use the existing measured-GPS progression rules.
    static var distanceIntervals: [WorkoutGuidance.Phase] {
        [.init(kind: .warmup, seconds: 600)] + (0..<6).flatMap { _ in
            [WorkoutGuidance.Phase(kind: .work, meters: 400), .init(kind: .recovery, meters: 200)]
        } + [.init(kind: .cooldown, seconds: 300)]
    }
}
