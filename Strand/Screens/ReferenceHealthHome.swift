import SwiftUI
import StrandDesign
import StrandAnalytics

/// The longer-term Health destination. Uses the existing Healthspan calculation and monitor routes.
struct ReferenceHealthHome: View {
    @EnvironmentObject private var repo: Repository
    @State private var curve: DaytimeStress.Result?

    private var readings: [BodyVitalReading] {
        BodyVitalSigns.readings(sourceRows: repo.vitalMetricRows, temperatureUnit: .celsius)
            .filter { $0.key != "spo2raw" }
    }

    var body: some View {
        ScreenScaffold(title: nil, onRefresh: { await repo.refresh() }, lazy: true) {
            Text("HEALTH").font(WhoopReferenceFont.label(14)).tracking(1.5)
                .frame(maxWidth: .infinity)
            HealthspanSection()
            NavigationLink(value: TabRoute.health) {
                VStack(alignment: .leading, spacing: NoopMetrics.space5) {
                    HStack {
                        Text("HEALTH MONITOR").whoopReferenceOverline()
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    HStack(spacing: NoopMetrics.space2) {
                        ForEach(readings) { reading in
                            VStack(spacing: NoopMetrics.space3) {
                                Text(shortLabel(reading.key)).font(WhoopReferenceFont.label(9))
                                    .foregroundStyle(StrandPalette.textSecondary)
                                Image(systemName: reading.value == nil ? "minus.square"
                                      : reading.banding.band == .inRange ? "checkmark.square.fill" : "exclamationmark.square.fill")
                                    .foregroundStyle(reading.value == nil ? StrandPalette.textTertiary
                                                     : reading.banding.band == .inRange ? StrandPalette.statusPositive : StrandPalette.statusWarning)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    Text("\(readings.filter { $0.value != nil && $0.banding.band == .inRange }.count)/5 metrics within range")
                        .font(StrandFont.subhead)
                }
                .foregroundStyle(StrandPalette.onDarkPrimary)
                .referenceMonitorCard()
            }
            .buttonStyle(.plain)
            ReferenceHomeStressChart(curve: curve, dailyScore: nil)
            Text("Health and stress readings are informational and are not a medical diagnosis.")
                .font(StrandFont.footnote).foregroundStyle(StrandPalette.textSecondary)
        }
        .task(id: repo.refreshSeq) {
            let result = await StressDayCurve.today(repo: repo,
                personalBaseline: PuffinExperiment.stressPersonalBaselineEnabled)
            guard !Task.isCancelled else { return }
            curve = result?.result
        }
    }

    private func shortLabel(_ key: String) -> String {
        switch key {
        case "resp": return "RESP"
        case "spo2": return "SpO₂"
        case "rhr": return "RHR"
        case "hrv": return "HRV"
        default: return "TEMP"
        }
    }
}
