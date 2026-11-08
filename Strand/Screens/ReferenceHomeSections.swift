import SwiftUI
import Charts
import StrandDesign
import StrandAnalytics
import WhoopStore

/// The existing alarm resolver owns both the displayed time and the on/off claim.
/// Analysis migration required: no. No alarm setting or historical score is changed.
struct ReferenceTonightSleepCard: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var behavior: BehaviorStore
    @EnvironmentObject private var router: NavRouter

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { tick in
            let fire = NextStrapAlarm.date(enabled: behavior.smartAlarmEnabled,
                willArm: NextStrapAlarm.willArm(whoop5Detected: model.whoop5Detected),
                minutes: behavior.smartAlarmMinutes, weekdays: behavior.smartAlarmWeekdays,
                overrides: WindDownNudge.perDayWakeOverrides, from: tick.date)
            let bedtime = fire.flatMap {
                Calendar.current.date(byAdding: .minute, value: -WindDownNudge.sleepNeedMinutes, to: $0)
            }
            VStack(alignment: .leading, spacing: NoopMetrics.space5) {
                Button { router.openAlarms() } label: {
                    HStack {
                        Text("TONIGHT'S SLEEP").whoopReferenceOverline()
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
                .buttonStyle(.plain)
                HStack(alignment: .top, spacing: NoopMetrics.space4) {
                    VStack(spacing: NoopMetrics.space2) {
                        Label(bedtime.map { NextStrapAlarm.Style.app.format($0) } ?? "—",
                              systemImage: "sun.horizon")
                            .font(WhoopReferenceFont.metric(23))
                        Text("PLANNED\nBEDTIME").whoopReferenceOverline()
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    Rectangle().fill(StrandPalette.hairline).frame(width: 50, height: 1)
                        .padding(.top, NoopMetrics.space4)
                    VStack(spacing: NoopMetrics.space2) {
                        Label(fire.map { NextStrapAlarm.Style.app.format($0) } ?? "—", systemImage: "alarm")
                            .font(WhoopReferenceFont.metric(23))
                        Text(fire == nil ? "ALARM OFF" : "ALARM ON")
                            .font(WhoopReferenceFont.label(11))
                            .foregroundStyle(fire == nil ? StrandPalette.textTertiary : StrandPalette.statusPositive)
                        Text("EXACT TIME").whoopReferenceOverline()
                    }
                    .frame(maxWidth: .infinity)
                }
                Button { router.openAlarms() } label: {
                    Label("EDIT ALARM", systemImage: "pencil")
                        .font(WhoopReferenceFont.label(12))
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(WoopHomePalette.activityRow, in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(StrandPalette.onDarkPrimary)
            .referenceMonitorCard()
            .accessibilityIdentifier("woop.home.tonightSleep")
        }
    }
}

struct ReferenceHomeStressChart: View {
    let curve: DaytimeStress.Result?
    let dailyScore: Double?
    var isLoading = false

    private var latest: DaytimeStress.HourPoint? { curve?.scored.last }
    private var score: Double? { latest?.level ?? dailyScore }

    var body: some View {
        NavigationLink(value: TabRoute.stress) {
            VStack(alignment: .leading, spacing: NoopMetrics.space4) {
                HStack {
                    Text("STRESS MONITOR").whoopReferenceOverline()
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(StrandPalette.textTertiary)
                }
                HStack {
                    Text(latest.map { Date(timeIntervalSince1970: Double($0.startTs))
                        .formatted(.dateTime.hour().minute()) } ?? String(localized: "Daily score"))
                        .font(StrandFont.footnote).foregroundStyle(StrandPalette.textSecondary)
                    Spacer()
                    Text(score.map { StressBand(score: $0).title.uppercased() } ?? String(localized: "NO DATA"))
                        .font(WhoopReferenceFont.label(11))
                        .foregroundStyle(score.map { StressRamp.color($0) } ?? StrandPalette.textTertiary)
                    Text(score.map { String(format: "%.1f", $0) } ?? "—")
                        .font(WhoopReferenceFont.metric(17))
                }
                if let curve, !curve.scored.isEmpty {
                    DaytimeLoadLine(hours: curve.timeline).frame(height: 170)
                } else if isLoading {
                    ProgressView("Reading your heart data")
                        .frame(maxWidth: .infinity, minHeight: 100)
                } else {
                    Text("No intraday stress data for this day.")
                        .font(StrandFont.footnote).foregroundStyle(StrandPalette.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 100, alignment: .center)
                }
            }
            .foregroundStyle(StrandPalette.onDarkPrimary)
            .referenceMonitorCard()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("woop.home.stressChart")
    }
}

/// Stored daily values only. Missing days split the lines instead of inventing a zero or a bridge.
struct ReferenceRecoveryStrainChart: View {
    let days: [DailyMetric]
    let selectedDay: String
    let effortScale: EffortScale

    private struct Point: Identifiable {
        var id: String { "\(kind)-\(day)" }
        let day: String
        let kind: String
        let value: Double
        let segment: Int
    }

    private var keys: [String] {
        let parser = TodayView.dayParser
        guard let end = parser.date(from: selectedDay) else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return (0..<7).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: end).map { parser.string(from: $0) }
        }
    }

    private var points: [Point] {
        var output: [Point] = []
        for kind in ["strain", "recovery"] {
            var segment = 0
            for key in keys {
                let row = days.last(where: { $0.day == key })
                let value = kind == "strain" ? row?.strain : row?.recovery
                if let value, value.isFinite, (0...100).contains(value) {
                    output.append(Point(day: key, kind: kind, value: value, segment: segment))
                } else { segment += 1 }
            }
        }
        return output
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NoopMetrics.space4) {
            HStack {
                Text("STRAIN & RECOVERY").whoopReferenceOverline()
                Spacer()
                Image(systemName: "info.circle").foregroundStyle(StrandPalette.textTertiary)
                    .accessibilityLabel("Stored daily strain and recovery over seven days")
            }
            if points.isEmpty {
                Text("Your seven-day trend appears as daily scores become available.")
                    .font(StrandFont.subhead).foregroundStyle(StrandPalette.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart(points) { point in
                    LineMark(x: .value("Day", point.day), y: .value("Score", point.value),
                             series: .value("Series", "\(point.kind)-\(point.segment)"))
                        .foregroundStyle(point.kind == "strain" ? WoopHomePalette.strain : StrandPalette.statusPositive)
                    PointMark(x: .value("Day", point.day), y: .value("Score", point.value))
                        .foregroundStyle(point.kind == "strain" ? WoopHomePalette.strain : StrandPalette.chargeRingColor(point.value))
                }
                .chartXScale(domain: keys)
                .chartYScale(domain: 0...100)
                .chartXAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let day = value.as(String.self), let date = TodayView.dayParser.date(from: day) {
                                Text(date.formatted(.dateTime.weekday(.abbreviated).day()))
                                    .font(WhoopReferenceFont.body(9))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 33, 66, 100]) { value in
                        AxisGridLine().foregroundStyle(StrandPalette.hairline)
                        AxisValueLabel {
                            if let score = value.as(Double.self) {
                                Text(UnitFormatter.effortDisplay(score, scale: effortScale))
                                    .foregroundStyle(WoopHomePalette.strain)
                            }
                        }
                    }
                    AxisMarks(position: .trailing, values: [0, 33, 66, 100]) { value in
                        AxisValueLabel {
                            if let score = value.as(Int.self) { Text("\(score)%").foregroundStyle(StrandPalette.statusPositive) }
                        }
                    }
                }
                .frame(height: 210)
            }
        }
        .referenceMonitorCard()
        .accessibilityIdentifier("woop.home.strainRecovery")
    }
}

/// Weekly rows reuse imported zone splits and the workout detail's source-specific HR fallback.
struct ReferenceWeeklyTrainingRows: View {
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var profile: ProfileStore
    let dayKey: String
    @State private var lowZoneMinutes: Double?
    @State private var highZoneMinutes: Double?
    @State private var strengthMinutes: Double?

    var body: some View {
        VStack(spacing: NoopMetrics.space3) {
            row("HR ZONES 1–3 (WEEKLY)", symbol: "heart", minutes: lowZoneMinutes)
            row("HR ZONES 4–5 (WEEKLY)", symbol: "heart.fill", minutes: highZoneMinutes)
            row("STRENGTH ACTIVITY TIME", symbol: "dumbbell", minutes: strengthMinutes)
            Text("Recorded workouts; zone totals include sessions with available heart-rate data.")
                .font(StrandFont.footnote).foregroundStyle(StrandPalette.textSecondary)
        }
        .task(id: "\(repo.refreshSeq)-\(dayKey)-\(profile.hrZoneSet)") { await load() }
    }

    private func row(_ title: LocalizedStringKey, symbol: String, minutes: Double?) -> some View {
        NavigationLink(value: TabRoute.workouts) {
            HStack(spacing: NoopMetrics.space3) {
                Image(systemName: symbol).foregroundStyle(StrandPalette.textSecondary)
                Text(title).font(WhoopReferenceFont.label(11)).tracking(0.7)
                Spacer(minLength: NoopMetrics.space2)
                Text(minutes.map { value in
                    let total = max(0, Int(value.rounded()))
                    return String(format: "%d:%02d", total / 60, total % 60)
                } ?? "—")
                .font(WhoopReferenceFont.metric(23))
            }
            .foregroundStyle(StrandPalette.onDarkPrimary)
            .referenceMonitorCard()
        }
        .buttonStyle(.plain)
    }

    private func load() async {
        lowZoneMinutes = nil; highZoneMinutes = nil; strengthMinutes = nil
        guard let date = PeriodGoalTracker.date(dayKey, calendar: .current) else { return }
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        guard let week = calendar.dateInterval(of: .weekOfYear, for: date),
              let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) else { return }
        let offset = max(0, calendar.dateComponents([.day], from: date, to: Date()).day ?? 0)
        let rows = await repo.workoutRows(days: offset + 8, reconcileHrCap: 0)
        let workouts = OverviewDashboardView.uniqueActivityWorkouts(rows).filter {
            let start = Date(timeIntervalSince1970: Double($0.startTs))
            return start >= week.start && start < end
        }
        guard !Task.isCancelled, !workouts.isEmpty else { return }
        var low: Double = 0, high: Double = 0, strength: Double = 0
        var hasZones = false
        for workout in workouts {
            guard !Task.isCancelled else { return }
            let minutes = max(0, workout.durationS ?? Double(workout.endTs - workout.startTs)) / 60
            if HealthspanWindow.countsAsStrength(storedName: workout.sport) { strength += minutes }
            let zones: [Double]?
            if let percentages = WorkoutZones.percents(workout.zonesJSON) {
                zones = percentages.map { minutes * $0 / 100 }
            } else {
                zones = await repo.workoutZoneMinutes(from: workout.startTs, to: workout.endTs,
                    zoneSet: profile.hrZoneSet, source: workout.source)
            }
            if let zones, zones.count == 5 {
                low += zones.prefix(3).reduce(0, +)
                high += zones.suffix(2).reduce(0, +)
                hasZones = true
            }
        }
        guard !Task.isCancelled else { return }
        lowZoneMinutes = hasZones ? low : nil
        highZoneMinutes = hasZones ? high : nil
        strengthMinutes = strength
    }
}
