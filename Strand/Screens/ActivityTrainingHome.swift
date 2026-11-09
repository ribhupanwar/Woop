import SwiftUI
import StrandDesign
import StrandTraining
import StrandCore
import WhoopStore

/// Train first; the editable archive and detailed charts remain in Activity's History view.
struct ActivityTrainingHome: View {
    let rows: [WorkoutRow]
    let historyLoaded: Bool
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var session: ActiveSessionController
    @StateObject private var gym = TrainingHubModel()
    @State private var showsRunningPlan = false
    @State private var focusRegion: TrainingBodyRegion?
    @AppStorage(UnitPrefs.systemKey) private var units = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.distanceSystemKey) private var distanceUnits = ""
    private var distanceSystem: UnitSystem {
        UnitPrefs.resolveDistance(system: UnitSystem(rawValue: units) ?? .metric, override: distanceUnits)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NoopMetrics.sectionGap) {
            VStack(alignment: .leading, spacing: NoopMetrics.space1) {
                Text("Your training starts here").font(WhoopReferenceFont.heading(26))
                Text(Date.now, format: .dateTime.weekday(.wide).day().month(.abbreviated))
                    .font(WhoopReferenceFont.body(12)).foregroundStyle(StrandPalette.textSecondary)
            }
            if session.hasLiveSession {
                NoopButton("Resume workout", systemImage: "play.fill", kind: .primary, fullWidth: true) {
                    session.present()
                }
                Text(verbatim: session.runningTitle).font(WhoopReferenceFont.body(12))
            } else {
                runCard
                gymCard
            }
            if historyLoaded { weekCard }
            else { ProgressView("Loading training history…") }
            HStack(spacing: NoopMetrics.space3) {
                NavigationLink(value: TabRoute.coach) {
                    Label("Training coach", systemImage: "bubble.left.and.bubble.right")
                }
                Spacer(minLength: 0)
                NavigationLink(value: TabRoute.trainingLoad) {
                    Label("Training load", systemImage: "chart.xyaxis.line")
                }
            }
            .font(WhoopReferenceFont.body(12)).frame(minHeight: 44)
            NavigationLink(value: TabRoute.goals) {
                Label("Race goals & progress", systemImage: "flag.checkered")
                    .font(WhoopReferenceFont.body(13)).frame(minHeight: 44)
            }
        }
        .task(id: repo.refreshSeq) { await gym.load(repo: repo, session: session) }
        .onChange(of: session.hasLiveSession) { live in
            if !live { Task { await gym.load(repo: repo, session: session, force: true) } }
        }
        .sheet(isPresented: $showsRunningPlan) { WorkoutPlanEditorView(gpsEnabled: true) }
        .sheet(item: $focusRegion) { region in
            ActivityMuscleSessionPicker(region: region, exercises: gym.exercises) { routine in
                session.update(context: gym.startContext)
                focusRegion = nil
                session.requestStrength(routines: [routine], closingSheet: true)
            }
        }
    }

    private var runCard: some View {
        NoopCard {
            VStack(alignment: .leading, spacing: NoopMetrics.space3) {
                Label("RUN", systemImage: "figure.run")
                    .font(WhoopReferenceFont.label(13)).foregroundStyle(WoopHomePalette.strain)
                Text("Road, track or intervals").font(WhoopReferenceFont.heading(22))
                Text("GPS distance, pace and route. Heart rate when available.")
                    .font(WhoopReferenceFont.body(12)).foregroundStyle(StrandPalette.textSecondary)
                NoopButton("Start GPS run", systemImage: "play.fill", kind: .primary, fullWidth: true) {
                    guard let running = WorkoutCatalog.sport(named: "Running") else { return }
                    WorkoutQuickStart.start(running, with: WorkoutStartSettings(gpsEnabled: true, targetZone: nil), session: session)
                }
                Button("Intervals, plans & goal-time pacer") { showsRunningPlan = true }
                    .font(WhoopReferenceFont.body(12)).frame(minHeight: 44)
                if historyLoaded, let last = rows.filter({ ActivityTrainingWeek.isRunning($0) && Double($0.startTs) <= Date().timeIntervalSince1970 })
                    .max(by: { $0.startTs < $1.startTs }) {
                    Divider()
                    HStack {
                        Text("Last run").font(WhoopReferenceFont.body(12))
                        Spacer()
                        Text(Date(timeIntervalSince1970: Double(last.startTs)), format: .dateTime.day().month(.abbreviated))
                            .font(WhoopReferenceFont.body(11)).foregroundStyle(StrandPalette.textSecondary)
                    }
                    NavigationLink(value: TabRoute.workoutDetail(startTs: last.startTs, sport: last.sport)) {
                        Label("Open run analysis", systemImage: "chart.xyaxis.line")
                            .font(WhoopReferenceFont.body(12)).frame(minHeight: 44)
                    }
                }
            }
        }
    }

    private var gymCard: some View {
        let routines = gym.routines(on: Date())
        return NoopCard {
            VStack(alignment: .leading, spacing: NoopMetrics.space3) {
                Label("GYM", systemImage: "dumbbell.fill")
                    .font(WhoopReferenceFont.label(13)).foregroundStyle(WoopHomePalette.healthGood)
                if !gym.loaded {
                    ProgressView("Loading your routine…")
                } else {
                    Text(routines.isEmpty ? String(localized: "Freestyle strength") : routines.map(\.title).joined(separator: " + "))
                        .font(WhoopReferenceFont.heading(22))
                    Text(routines.isEmpty ? String(localized: "Choose exercises as you train. Save actual sets, reps and weight.")
                         : String(localized: "Today's scheduled routine, with your exercise targets and rest timers."))
                        .font(WhoopReferenceFont.body(12)).foregroundStyle(StrandPalette.textSecondary)
                    NoopButton(routines.isEmpty ? "Start freestyle gym" : "Start today's routine",
                               systemImage: "play.fill", kind: .primary, fullWidth: true) {
                        session.update(context: gym.startContext)
                        session.requestStrength(routines: routines)
                    }
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: NoopMetrics.space2) {
                        ForEach([TrainingBodyRegion.chest, .back, .legs, .shoulders, .arms, .core]) { region in
                            Button(ActivityMuscleSessionPicker.title(region)) { focusRegion = region }
                                .font(WhoopReferenceFont.body(12))
                                .padding(.horizontal, NoopMetrics.space3).frame(minHeight: 44)
                                .background(WoopHomePalette.healthGood.opacity(0.12), in: Capsule())
                                .disabled(!gym.loaded)
                        }
                    }
                }
                NavigationLink { TrainingHubView() } label: {
                    Label("Routines, exercises & openGym import", systemImage: "list.clipboard")
                        .font(WhoopReferenceFont.body(12)).frame(minHeight: 44)
                }
            }
        }
    }

    private var weekCard: some View {
        let week = ActivityTrainingWeek(rows: rows, now: Date(), calendar: .current)
        return NoopCard {
            VStack(alignment: .leading, spacing: NoopMetrics.space3) {
                Text("LAST 7 DAYS").font(WhoopReferenceFont.label(12))
                HStack(alignment: .top, spacing: NoopMetrics.space4) {
                    weekStat("Runs", value: String(week.runs))
                    weekStat("Run distance", value: week.runMeters.map {
                        UnitFormatter.distanceFromMeters($0, system: distanceSystem)
                    } ?? "—")
                    weekStat("Sessions", value: String(week.sessions))
                }
                Text("Distance available for \(week.runsWithDistance) of \(week.runs) runs.")
                    .font(WhoopReferenceFont.body(10)).foregroundStyle(StrandPalette.textSecondary)
            }
        }
    }

    private func weekStat(_ label: LocalizedStringKey, value: String) -> some View {
        VStack(alignment: .leading, spacing: NoopMetrics.space1) {
            Text(verbatim: value).font(WoopDashboardMetricStyle.value).lineLimit(1).minimumScaleFactor(0.7)
            Text(label).font(WhoopReferenceFont.body(11)).foregroundStyle(StrandPalette.textSecondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Calendar-bounded presentation totals; no forecasts, imported future sessions or fabricated distance.
struct ActivityTrainingWeek {
    let runs: Int
    let sessions: Int
    let runMeters: Double?
    let runsWithDistance: Int

    static func isRunning(_ row: WorkoutRow) -> Bool {
        let sport = WorkoutSource.displaySport(row.sport)
        return WorkoutCatalog.isOnFoot(sport) && sport.lowercased().contains("run")
    }

    init(rows: [WorkoutRow], now: Date, calendar: Calendar) {
        let start = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: now)) ?? now
        let recent = rows.filter {
            let date = Date(timeIntervalSince1970: Double($0.startTs))
            return date >= start && date <= now
        }
        let running = recent.filter(Self.isRunning)
        sessions = recent.count
        runs = running.count
        let distances = running.compactMap(\.distanceM).filter { $0.isFinite && $0 > 0 }
        runsWithDistance = distances.count
        runMeters = distances.isEmpty ? nil : distances.reduce(0, +)
    }
}

/// Explicit muscle/exercise selection starts the real set logger; it never fabricates performed reps.
private struct ActivityMuscleSessionPicker: View {
    let region: TrainingBodyRegion
    let exercises: [TrainingExercise]
    let onStart: (TrainingRoutine) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selected: [String] = []
    @State private var query = ""
    @State private var sets = 3

    private let prepared: [TrainingExercise]

    init(region: TrainingBodyRegion, exercises: [TrainingExercise], onStart: @escaping (TrainingRoutine) -> Void) {
        self.region = region
        self.exercises = exercises
        self.onStart = onStart
        // Anatomy lookup/sort is prepared once for this picker, not on every selection/search render.
        self.prepared = exercises.filter { TrainingLibraryPreparation.Info($0).region == region }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    private var matching: [TrainingExercise] {
        prepared.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Stepper("Working sets per exercise: \(sets)", value: $sets, in: 1...6)
                    Text("Choose your exercises in workout order. Starting targets are editable; enter actual reps and load while training. Motion trial only suggests set endings.")
                        .font(.footnote).foregroundStyle(StrandPalette.textSecondary)
                }
                Section("Choose exercises") {
                    if matching.isEmpty { Text("No matching exercises. Try another search or add a custom exercise in the library.") }
                    ForEach(matching) { exercise in
                        Button {
                            if selected.contains(exercise.id) { selected.removeAll { $0 == exercise.id } }
                            else { selected.append(exercise.id) }
                        } label: {
                            HStack {
                                Text(verbatim: exercise.title).foregroundStyle(StrandPalette.textPrimary)
                                Spacer()
                                if let index = selected.firstIndex(of: exercise.id) {
                                    Text(index + 1, format: .number)
                                    Image(systemName: "checkmark.circle.fill")
                                } else { Image(systemName: "circle") }
                            }.frame(minHeight: 44)
                        }
                        .accessibilityAddTraits(selected.contains(exercise.id) ? [.isSelected] : [])
                    }
                }
            }
            .searchable(text: $query)
            .navigationTitle(Self.title(region))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start (\(selected.count))") {
                        let picked = selected.compactMap { id in exercises.first { $0.id == id } }
                        guard !picked.isEmpty else { return }
                        let routine = TrainingRoutine(title: Self.title(region), exercises: picked.map {
                            RoutineExercise(exerciseId: $0.id, sets: RoutineSetPlan.defaults(for: $0.mode, count: sets),
                                            loadSemantics: $0.effectiveLoadSemantics)
                        })
                        onStart(routine)
                    }.disabled(selected.isEmpty)
                }
            }
        }
    }

    static func title(_ region: TrainingBodyRegion) -> String {
        switch region {
        case .chest: return String(localized: "Chest")
        case .back: return String(localized: "Back")
        case .legs: return String(localized: "Legs")
        case .shoulders: return String(localized: "Shoulders")
        case .arms: return String(localized: "Arms")
        case .core: return String(localized: "Core")
        case .other: return String(localized: "Other")
        }
    }
}
