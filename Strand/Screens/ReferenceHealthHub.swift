import SwiftUI
import StrandDesign
import StrandAnalytics

/// Health's landing page: existing age calculation and source-resolved monitors, never example data.
struct ReferenceHealthHub: View {
    @EnvironmentObject private var repo: Repository
    @Environment(\.dashboardIsActive) private var active
    @State private var stress: DaytimeStress.Result?
    var body: some View {
        ScreenScaffold(title: "Health", lazy: true) {
            HealthspanSection()
            HomeHealthMonitorCard(dayKey: Repository.logicalDayKey(Date()))
            RecordedBloodPressureCard()
            NavigationLink(value: TabRoute.stress) {
                NoopCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("STRESS MONITOR").font(WhoopReferenceFont.label(13)).tracking(1)
                            Spacer(); Image(systemName: "chevron.right")
                        }
                        if let stress, stress.hours.contains(where: { $0.level != nil }) {
                            HStack(alignment: .center, spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("TODAY’S HIGH STRESS").font(WhoopReferenceFont.label(10))
                                    Text(ReferenceSleepPlan.duration(stress.highStressMinutes))
                                        .font(WhoopReferenceFont.heading(29).bold())
                                    Text("Estimated h:mm").font(WhoopReferenceFont.body(10))
                                        .foregroundStyle(StrandPalette.textSecondary)
                                }
                                DaytimeLoadLine(hours: stress.timeline, chartHeight: 100)
                            }
                        } else {
                            Text("Needs recorded daytime sensor data")
                                .font(WhoopReferenceFont.body(12)).foregroundStyle(StrandPalette.textSecondary)
                        }
                    }
                }
            }.buttonStyle(.plain)
        }
        .task(id: "\(repo.refreshSeq)|\(active)") {
            guard active else { return }
            let result = await StressDayCurve.today(repo: repo,
                personalBaseline: PuffinExperiment.stressPersonalBaselineEnabled)
            guard !Task.isCancelled else { return }
            stress = result?.result
        }
    }
}
