import SwiftUI
import StrandDesign
import StrandAnalytics

/// Presentation-only bedtime estimate over the existing nap-credited debt ledger. Debt repayment is
/// spread across nights (at most two extra hours); this does not predict sleep stages or consistency.
struct ReferenceSleepPlan: Equatable {
    let baseMinutes: Int
    let repaymentMinutes: Int
    var targetMinutes: Int { baseMinutes + repaymentMinutes }
    init?(ledger: SleepDebtLedger) {
        guard ledger.nightCount > 0, ledger.needMin.isFinite, (1...1440).contains(ledger.needMin),
              ledger.balanceMin.isFinite else { return nil }
        baseMinutes = Int(ledger.needMin.rounded())
        repaymentMinutes = Int(min(120, max(0, -ledger.balanceMin)).rounded())
    }
    func bedtime(wake: Date) -> Date { wake.addingTimeInterval(-Double(targetMinutes) * 60) }
    static func duration(_ minutes: Int) -> String { String(format: "%d:%02d", minutes / 60, minutes % 60) }
}

struct TonightSleepCard: View {
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var behavior: BehaviorStore
    @Environment(\.dashboardAppModel) private var appModel
    @Environment(\.dashboardIsActive) private var active
    @State private var plan: ReferenceSleepPlan?
    @State private var showsPlanner = false
    private var wake: Date? {
        guard let appModel else { return nil }
        return NextStrapAlarm.date(enabled: behavior.smartAlarmEnabled,
            willArm: NextStrapAlarm.willArm(whoop5Detected: appModel.whoop5Detected),
            minutes: behavior.smartAlarmMinutes, weekdays: behavior.smartAlarmWeekdays,
            overrides: WindDownNudge.perDayWakeOverrides, from: Date())
    }
    private var alarmOn: Bool {
        guard let appModel else { return false }
        return NextStrapAlarm.date(enabled: behavior.smartAlarmEnabled,
            willArm: NextStrapAlarm.willArm(whoop5Detected: appModel.whoop5Detected),
            minutes: behavior.smartAlarmMinutes, weekdays: behavior.smartAlarmWeekdays,
            overrides: WindDownNudge.perDayWakeOverrides, from: Date()) != nil
    }
    var body: some View {
        Button { showsPlanner = true } label: {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("TONIGHT’S SLEEP").font(WhoopReferenceFont.label(13)).tracking(1)
                    Spacer(); Image(systemName: "chevron.right")
                }
                HStack(alignment: .top) {
                    sleepTime(symbol: "sun.horizon", value: bedtimeText, caption: "RECOMMENDED BEDTIME")
                    Spacer(minLength: 8)
                    sleepTime(symbol: "alarm", value: wake.map { NextStrapAlarm.Style.app.format($0) } ?? "—",
                              caption: alarmOn ? "ALARM ENABLED" : "PLANNED WAKE TIME")
                }
                if plan == nil {
                    Text("Sleep history is needed for a debt-based bedtime recommendation.")
                        .font(WhoopReferenceFont.body(11)).foregroundStyle(StrandPalette.textSecondary)
                }
                Label("EDIT SLEEP PLAN & ALARM", systemImage: "pencil")
                    .font(WhoopReferenceFont.label(12)).tracking(0.7)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(WoopHomePalette.activityRow, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(16).foregroundStyle(StrandPalette.textPrimary)
            .background(WoopHomePalette.activityCard, in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain).accessibilityIdentifier("woop.home.tonightSleep")
        .sheet(isPresented: $showsPlanner) {
            ReferenceSleepPlanner(plan: plan, wake: wake, alarmOn: alarmOn)
        }
        .task(id: "\(repo.refreshSeq)|\(active)") {
            guard active else { return }
            let habitual = await repo.habitualMidsleepSec(days: 30)
            guard !Task.isCancelled else { return }
            let groups = SleepModel.navDays(navSessions: repo.sleeps)
            let naps = SleepModel.napSleepMinutesByDay(navDays: groups, habitualMidsleepSec: habitual)
            plan = ReferenceSleepPlan(ledger: SleepModel.debtLedger(days: repo.days, napSleepMinByDay: naps))
        }
    }
    private var bedtimeText: String {
        guard let plan, let wake else { return "—" }
        return NextStrapAlarm.Style.app.format(plan.bedtime(wake: wake))
    }
    private func sleepTime(symbol: String, value: String, caption: LocalizedStringKey) -> some View {
        VStack(spacing: 10) {
            Label(value, systemImage: symbol).font(WhoopReferenceFont.heading(24).bold())
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(caption).font(WhoopReferenceFont.label(10)).tracking(1)
                .multilineTextAlignment(.center).foregroundStyle(StrandPalette.textSecondary)
        }.frame(maxWidth: .infinity)
    }
}

private struct ReferenceSleepPlanner: View {
    let plan: ReferenceSleepPlan?
    let wake: Date?
    let alarmOn: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showsAlarms = false
    var body: some View {
        NavigationStack {
            ScreenScaffold(title: nil, lazy: true) {
                if let plan, let wake {
                    Text("Go to bed at \(NextStrapAlarm.Style.app.format(plan.bedtime(wake: wake))) to allow \(ReferenceSleepPlan.duration(plan.targetMinutes)) before your planned wake time.")
                        .font(WhoopReferenceFont.heading(23)).multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity).padding(.vertical, 30)
                    HStack {
                        timeColumn("SUGGESTED BEDTIME", date: plan.bedtime(wake: wake))
                        Spacer()
                        timeColumn("YOUR WAKE TIME", date: wake)
                    }
                    Rectangle().fill(WoopHomePalette.sleep.opacity(0.35)).frame(height: 28)
                        .overlay { Text(ReferenceSleepPlan.duration(plan.targetMinutes)).font(WhoopReferenceFont.label(16)) }
                    Text("TIME IN BED · WOOP ESTIMATE").font(WhoopReferenceFont.label(11)).tracking(1)
                    WoopMetricRow("Base sleep need", value: ReferenceSleepPlan.duration(plan.baseMinutes), symbol: "moon")
                    WoopMetricRow("Debt repayment tonight", value: ReferenceSleepPlan.duration(plan.repaymentMinutes), symbol: "clock.arrow.circlepath")
                    Text("Uses your existing nap-credited sleep-debt estimate, with up to two extra hours tonight. Time in bed does not guarantee time asleep or a sleep-consistency score.")
                        .font(WhoopReferenceFont.body(12)).foregroundStyle(StrandPalette.textSecondary)
                } else {
                    Text("Record sleep first to calculate your bedtime recommendation.")
                        .font(WhoopReferenceFont.body(15)).padding(.vertical, 30)
                }
                NoopButton(alarmOn ? "Edit enabled alarm" : "Configure wake time & alarm",
                           systemImage: "alarm", kind: .secondary, fullWidth: true) { showsAlarms = true }
                Text("Keep a phone alarm as backup. Strap alarm availability depends on your connected model and enabled features.")
                    .font(WhoopReferenceFont.body(11)).foregroundStyle(StrandPalette.textSecondary)
            }
            .navigationTitle("Sleep Planner")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .sheet(isPresented: $showsAlarms) { NavigationStack { SmartAlarmView() } }
        }
    }
    private func timeColumn(_ title: LocalizedStringKey, date: Date) -> some View {
        VStack(spacing: 8) {
            Text(NextStrapAlarm.Style.app.format(date)).font(WhoopReferenceFont.heading(28).bold())
            Text(title).font(WhoopReferenceFont.label(10)).tracking(1).foregroundStyle(StrandPalette.textSecondary)
        }
    }
}
