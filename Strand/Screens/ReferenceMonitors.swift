import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

// Analysis migration required: no. Reference presentation uses the existing vital and stress engines.

extension View {
    func referenceMonitorCard() -> some View {
        padding(NoopMetrics.space4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(WoopHomePalette.activityCard,
                        in: RoundedRectangle(cornerRadius: NoopMetrics.cardRadius, style: .continuous))
    }
}

/// A compact two-card entry under the Home rings. All five statuses use the detail screen's resolver.
struct ReferenceMonitorEntries: View {
    let readings: [BodyVitalReading]
    let stress: Double?
    var stressCaption: String = String(localized: "Daily score")

    private var core: [BodyVitalReading] { readings.filter { $0.key != "spo2raw" } }
    private var measured: Int { core.filter { $0.value != nil && $0.caveat == nil }.count }
    private var inRange: Int {
        core.filter { $0.value != nil && $0.caveat == nil && $0.banding.band == .inRange }.count
    }
    private var status: String {
        if measured == 0 { return String(localized: "NO DATA") }
        if inRange < measured { return String(localized: "CHECK METRICS") }
        return measured == 5 ? String(localized: "WITHIN RANGE") : String(localized: "PARTIAL DATA")
    }

    var body: some View {
        HStack(alignment: .top, spacing: NoopMetrics.space3) {
            NavigationLink(value: TabRoute.health) {
                VStack(alignment: .leading, spacing: NoopMetrics.space4) {
                    heading("HEALTH MONITOR")
                    HStack(spacing: NoopMetrics.space2) {
                        Image(systemName: measured == 5 && inRange == 5 ? "checkmark" : "waveform.path.ecg")
                            .padding(NoopMetrics.space2)
                            .background(StrandPalette.statusPositive.opacity(0.14), in: RoundedRectangle(cornerRadius: 5))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(status).font(WhoopReferenceFont.label(10)).lineLimit(1).minimumScaleFactor(0.7)
                            Text("\(inRange)/5 Metrics").font(WhoopReferenceFont.body(10))
                                .foregroundStyle(StrandPalette.textSecondary)
                        }
                    }
                    .foregroundStyle(measured > 0 && inRange < measured ? StrandPalette.statusWarning : StrandPalette.statusPositive)
                }
                .referenceMonitorCard()
            }
            .accessibilityIdentifier("woop.home.healthMonitor")
            NavigationLink(value: TabRoute.stress) {
                VStack(alignment: .leading, spacing: NoopMetrics.space4) {
                    heading("STRESS MONITOR")
                    HStack(spacing: NoopMetrics.space2) {
                        Text(stress.map { String(format: "%.1f", $0) } ?? "—")
                            .font(WhoopReferenceFont.metric(14))
                            .padding(NoopMetrics.space2)
                            .background(StrandPalette.statusPositive.opacity(0.14), in: RoundedRectangle(cornerRadius: 5))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(stress.map { StressBand(score: $0).title.uppercased() } ?? String(localized: "NO DATA"))
                                .font(WhoopReferenceFont.label(10))
                            Text(stressCaption).font(WhoopReferenceFont.body(10))
                                .foregroundStyle(StrandPalette.textSecondary)
                        }
                    }
                    .foregroundStyle(stress.map { StressRamp.color($0) } ?? StrandPalette.textTertiary)
                }
                .referenceMonitorCard()
            }
            .accessibilityIdentifier("woop.home.stressMonitor")
        }
        .buttonStyle(.plain)
    }

    private func heading(_ title: LocalizedStringKey) -> some View {
        HStack(spacing: 3) {
            Text(title).font(WhoopReferenceFont.label(10)).tracking(0.7)
                .lineLimit(1).minimumScaleFactor(0.7)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(StrandFont.caption)
                .foregroundStyle(StrandPalette.textTertiary)
        }
        .foregroundStyle(StrandPalette.onDarkPrimary)
    }
}

/// The metric value, units, provenance and banding are unchanged from the existing Health monitor.
struct ReferenceVitalTile: View {
    let reading: BodyVitalReading

    private var symbol: String {
        switch reading.key {
        case "resp": return "lungs"
        case "spo2": return "drop"
        case "rhr": return "heart"
        case "hrv": return "waveform.path.ecg"
        default: return "thermometer.medium"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: NoopMetrics.space3) {
            Label(reading.label.uppercased(), systemImage: symbol)
                .font(WhoopReferenceFont.label(10))
                .foregroundStyle(StrandPalette.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(reading.value.map { reading.format($0) } ?? "—")
                    .font(WhoopReferenceFont.score(34))
                    .foregroundStyle(StrandPalette.onDarkPrimary)
                Text(reading.unit).font(WhoopReferenceFont.label(12))
                    .foregroundStyle(StrandPalette.textSecondary)
            }
            .lineLimit(1).minimumScaleFactor(0.65)
            Text(reading.stateCaption)
                .font(WhoopReferenceFont.body(10))
                .foregroundStyle(reading.banding.band == .outOfRange ? StrandPalette.statusWarning
                                 : reading.banding.band == .inRange ? StrandPalette.statusPositive : StrandPalette.textTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(minHeight: 110, alignment: .topLeading)
        .referenceMonitorCard()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reading.accessibilityText)
    }
}

/// A 240-degree arc with a marker on the existing 0–3 scale; no new stress calculation.
struct ReferenceStressGauge: View {
    let score: Double?
    let caption: String

    private var fraction: CGFloat { CGFloat(min(3, max(0, score ?? 0)) / 3) }

    var body: some View {
        ZStack {
            Circle().trim(from: 0, to: 2.0 / 3)
                .stroke(StrandPalette.hairline, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(150))
            Circle().trim(from: 0, to: 2.0 / 3)
                .stroke(AngularGradient(gradient: StressRamp.gradient, center: .center,
                                        startAngle: .degrees(0), endAngle: .degrees(240)),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(150))
            if score != nil {
                GeometryReader { proxy in
                    let radius = min(proxy.size.width, proxy.size.height) / 2
                    Capsule().fill(StrandPalette.onDarkPrimary)
                        .frame(width: 6, height: 26)
                        .offset(y: -radius + 10)
                        .rotationEffect(.degrees(-120 + Double(fraction) * 240))
                        .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
            }
            VStack(spacing: NoopMetrics.space2) {
                Text(score.map { String(format: "%.1f", $0) } ?? "—")
                    .font(WhoopReferenceFont.score(58))
                    .foregroundStyle(StrandPalette.onDarkPrimary)
                Text(score.map { StressBand(score: $0).title.uppercased() } ?? String(localized: "NO DATA"))
                    .font(WhoopReferenceFont.label(14)).tracking(1)
                    .foregroundStyle(score.map { StressRamp.color($0) } ?? StrandPalette.textTertiary)
                Text(caption).font(StrandFont.footnote).foregroundStyle(StrandPalette.textSecondary)
            }
            .offset(y: 20)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 280)
        .padding(.horizontal, NoopMetrics.space5)
        .accessibilityElement(children: .combine)
    }
}

struct ReferenceStressSplit: View {
    let title: LocalizedStringKey
    let hours: [DaytimeStress.HourPoint]

    private var totals: StressTotals { StressTotals(hours: hours) }
    private let bands: [StressBand] = [.low, .medium, .high]

    var body: some View {
        VStack(alignment: .leading, spacing: NoopMetrics.space4) {
            Text(title).font(WhoopReferenceFont.label(12)).tracking(1)
            Text("SCORED WAKING HOURS").whoopReferenceOverline()
            GeometryReader { proxy in
                HStack(spacing: 0) {
                    ForEach(Array(bands.enumerated()), id: \.offset) { _, band in
                        Rectangle().fill(color(band))
                            .frame(width: proxy.size.width * totals.fraction(band))
                    }
                }
                .background(StrandPalette.hairline)
            }
            .frame(height: 12)
            HStack {
                ForEach(Array(bands.enumerated()), id: \.offset) { _, band in
                    VStack(alignment: .leading, spacing: NoopMetrics.space2) {
                        Text(totals.total == 0 ? "—" : "\(totals.hours(band)):00")
                            .font(WhoopReferenceFont.metric(23))
                        Text(band.title.uppercased()).font(WhoopReferenceFont.label(10))
                            .foregroundStyle(color(band))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            Text("Hourly estimates. Activity-masked and missing hours are excluded.")
                .font(StrandFont.footnote).foregroundStyle(StrandPalette.textSecondary)
        }
        .referenceMonitorCard()
    }

    private func color(_ band: StressBand) -> Color {
        switch band {
        case .low: return StressRamp.calm
        case .medium: return StressRamp.steady
        case .high: return StressRamp.tense
        }
    }
}
