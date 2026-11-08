import SwiftUI
import StrandDesign
import StrandAnalytics

/// The longer-term Health destination. Uses the existing Healthspan calculation and monitor routes.
struct ReferenceHealthHome: View {
    @EnvironmentObject private var repo: Repository
    @State private var curve: DaytimeStress.Result?
    @State private var curveLoaded = false
    @State private var hrvOverCountByDay: [String: Double] = [:]
    @AppStorage(UnitPrefs.systemKey) private var unitSystemRaw = UnitSystem.metric.rawValue
    @AppStorage(UnitPrefs.temperatureKey) private var temperatureRaw = ""
    @AppStorage(UnitPrefs.skinTempDisplayKey) private var skinTempRaw = ""

    private var readings: [BodyVitalReading] {
        BodyVitalSigns.readings(sourceRows: repo.vitalMetricRows,
            temperatureUnit: UnitPrefs.resolveTemperature(system: UnitSystem(rawValue: unitSystemRaw) ?? .metric,
                                                          override: temperatureRaw),
            hrvOverCountByDay: hrvOverCountByDay,
            skinTempPreferred: SkinTempDisplay.Kind(rawValue: skinTempRaw) ?? .absolute)
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
                                Image(systemName: reading.value == nil || reading.caveat != nil ? "minus.square"
                                      : reading.banding.band == .inRange ? "checkmark.square.fill" : "exclamationmark.square.fill")
                                    .foregroundStyle(reading.value == nil || reading.caveat != nil ? StrandPalette.textTertiary
                                                     : reading.banding.band == .inRange ? StrandPalette.statusPositive : StrandPalette.statusWarning)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    Text("\(readings.filter { $0.value != nil && $0.caveat == nil && $0.banding.band == .inRange }.count)/5 metrics within range")
                        .font(StrandFont.subhead)
                }
                .foregroundStyle(StrandPalette.onDarkPrimary)
                .referenceMonitorCard()
            }
            .buttonStyle(.plain)
            ReferenceHomeStressChart(curve: curve, dailyScore: nil, isLoading: !curveLoaded)
            Text("Health and stress readings are informational and are not a medical diagnosis.")
                .font(StrandFont.footnote).foregroundStyle(StrandPalette.textSecondary)
        }
        .task(id: repo.refreshSeq) {
            let flags = await repo.exploreSeries(key: "hrv_rr_overcount", source: Repository.whoopSource, days: 14)
            guard !Task.isCancelled else { return }
            hrvOverCountByDay = Dictionary(flags.map { ($0.day, $0.value) }, uniquingKeysWith: { first, _ in first })
            let result = await StressDayCurve.today(repo: repo,
                personalBaseline: PuffinExperiment.stressPersonalBaselineEnabled)
            guard !Task.isCancelled else { return }
            curve = result?.result
            curveLoaded = true
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

/// Decorative calibration sphere; no age or progress is inferred while the engine has no result.
struct ReferenceCalibrationOrb: View {
    var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [StrandPalette.metricPurple.opacity(0.04),
                                                   StrandPalette.metricPurple.opacity(0.24)],
                                         center: .center, startRadius: 0, endRadius: 100))
                .overlay(Circle().stroke(StrandPalette.metricPurple.opacity(0.65), lineWidth: 1))
            Canvas { context, size in
                let radius = min(size.width, size.height) / 2
                for index in 0..<720 {
                    let vertical = 1 - 2 * Double(index) / 719
                    let angle = Double(index) * 2.399963229728653
                    let crossSection = sqrt(max(0, 1 - vertical * vertical))
                    let depth = sin(angle) * crossSection
                    let x = size.width / 2 + CGFloat(cos(angle) * crossSection) * radius
                    let y = size.height / 2 + CGFloat(vertical) * radius
                    let diameter = CGFloat(1.2 + (depth + 1) * 0.8)
                    context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: diameter, height: diameter)),
                        with: .color(StrandPalette.metricPurple.opacity(0.2 + (depth + 1) * 0.3)))
                }
            }
            .clipShape(Circle())
        }
        .frame(width: 180, height: 180)
        .padding(.vertical, NoopMetrics.space5)
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}
