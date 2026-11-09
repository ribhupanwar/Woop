import SwiftUI
import StrandDesign
import StrandAnalytics

struct ReferenceVitalTile: View {
    let reading: BodyVitalReading

    private var symbol: String {
        switch reading.key {
        case "resp": return "lungs"
        case "spo2": return "drop"
        case "rhr": return "heart"
        case "hrv": return "waveform.path.ecg"
        default: return "thermometer"
        }
    }

    private var tint: Color {
        if reading.caveat != nil { return StrandPalette.statusWarning }
        switch reading.banding.band {
        case .inRange: return WoopHomePalette.healthGood
        case .outOfRange: return StrandPalette.statusWarning
        case .noData: return StrandPalette.textSecondary
        }
    }

    private var bandLabel: String {
        if reading.caveat != nil { return String(localized: "Unverified") }
        switch (reading.banding.band, reading.banding.basis) {
        case (.noData, _): return String(localized: "No reading")
        case (.inRange, .personal): return String(localized: "In your range")
        case (.outOfRange, .personal): return String(localized: "Off baseline")
        case (.inRange, .population): return String(localized: "Typical range")
        case (.outOfRange, .population): return String(localized: "Outside typical")
        }
    }

    var body: some View {
        NoopCard(padding: 14) {
            VStack(alignment: .leading, spacing: 14) {
                Label(reading.label, systemImage: symbol)
                    .font(WhoopReferenceFont.label(11)).tracking(0.6).textCase(.uppercase)
                    .foregroundStyle(StrandPalette.textSecondary).lineLimit(2)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(reading.value.map(reading.format) ?? "—")
                        .font(WhoopReferenceFont.score(36)).foregroundStyle(StrandPalette.textPrimary)
                    if reading.value != nil {
                        Text(reading.unit).font(WhoopReferenceFont.metric(12))
                            .foregroundStyle(StrandPalette.textSecondary)
                    }
                }
                .lineLimit(1).minimumScaleFactor(0.65)
                Text(verbatim: bandLabel)
                    .font(WhoopReferenceFont.label(10)).foregroundStyle(tint)
                    .padding(.horizontal, 6).padding(.vertical, 4)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 5))
                Text(verbatim: reading.stateCaption).font(WhoopReferenceFont.body(9))
                    .foregroundStyle(StrandPalette.textSecondary).lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(reading.accessibilityText)
    }
}

/// Uses the existing local PDF renderer; nothing is sent until the wearer chooses a share destination.
struct HealthMonitorReportPage: View {
    let readings: [BodyVitalReading]

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Woop Health Monitor").font(.system(size: 26, weight: .bold))
            Text(Date().formatted(date: .abbreviated, time: .shortened)).font(.system(size: 12))
            Divider()
            ForEach(readings.filter { HealthMonitorSummary.keys.contains($0.key) }) { reading in
                VStack(alignment: .leading, spacing: 5) {
                    Text(reading.label).font(.system(size: 14, weight: .semibold))
                    Text(reading.formattedValue ?? String(localized: "No reading"))
                        .font(.system(size: 22, weight: .semibold))
                    Text(reading.stateCaption).font(.system(size: 10))
                }
                Divider()
            }
            Text("Readings and estimates with their recorded dates and sources. Informational, not a medical diagnosis.")
                .font(.system(size: 10))
            Spacer(minLength: 0)
        }
        .padding(32)
        .frame(width: 595, height: 842, alignment: .topLeading)
        .foregroundStyle(Color.black).background(Color.white)
        .environment(\.colorScheme, .light)
    }
}
