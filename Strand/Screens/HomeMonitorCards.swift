import SwiftUI
import StrandDesign
import StrandAnalytics
import StrandCore
import WhoopStore

/// Summary of the same five source-resolved vitals used by Health Monitor. Missing, carried or
/// unverified readings must not produce a green "5/5" claim for the selected day.
struct HealthMonitorSummary {
    enum State: Equatable { case noData, partial, withinRange, outOfRange }
    let day: String
    let available: Int
    let state: State
    static let keys: Set<String> = ["resp", "spo2", "rhr", "hrv", "skin"]

    init(readings: [BodyVitalReading], day: String) {
        self.day = day
        var valid: [String: BodyVitalReading] = [:]
        for reading in readings where Self.keys.contains(reading.key) && reading.day == day {
            guard let value = reading.value, value.isFinite, reading.caveat == nil,
                  reading.banding.band != .noData else { continue }
            valid[reading.key] = reading
        }
        available = valid.count
        if valid.values.contains(where: { $0.banding.band == .outOfRange }) { state = .outOfRange }
        else if available == Self.keys.count { state = .withinRange }
        else { state = available == 0 ? .noData : .partial }
    }
}

struct HomeHealthMonitorCard: View {
    let dayKey: String
    @EnvironmentObject private var repo: Repository
    @State private var summary = HealthMonitorSummary(readings: [], day: "")
    private var displayed: HealthMonitorSummary {
        summary.day == dayKey ? summary : HealthMonitorSummary(readings: [], day: dayKey)
    }

    var body: some View {
        NavigationLink(value: TabRoute.health) {
            HomeMonitorCard(title: "HEALTH MONITOR", badge: nil, symbol: displayed.state == .withinRange ? "checkmark" : "minus",
                            state: stateText, detail: String(localized: "\(displayed.available)/5 metrics"), tint: tint)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("woop.home.healthMonitor")
        .task(id: "\(repo.refreshSeq)|\(dayKey)") {
            let parser = DateFormatter()
            parser.dateFormat = "yyyy-MM-dd"
            parser.locale = Locale(identifier: "en_US_POSIX")
            parser.timeZone = .current
            guard let day = parser.date(from: dayKey) else { return }
            let calendar = Calendar.current
            let lookback = max(14, (calendar.dateComponents([.day], from: day, to: Date()).day ?? 0) + 2)
            let flags = await repo.exploreSeries(key: "hrv_rr_overcount", source: Repository.whoopSource, days: lookback)
            guard !Task.isCancelled else { return }
            let readings = BodyVitalSigns.readings(
                sourceRows: repo.vitalMetricRows.filter { $0.metric.day <= dayKey }, temperatureUnit: .celsius,
                now: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day,
                hrvOverCountByDay: Dictionary(flags.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last }),
                skinTempPreferred: .deviation)
            summary = HealthMonitorSummary(readings: readings, day: dayKey)
        }
    }

    private var stateText: String {
        switch displayed.state {
        case .noData: return String(localized: "No readings")
        case .partial: return String(localized: "Partial readings")
        case .withinRange: return String(localized: "Within range")
        case .outOfRange: return String(localized: "Check metrics")
        }
    }

    private var tint: Color {
        switch displayed.state {
        case .withinRange: return StrandPalette.statusPositive
        case .outOfRange: return StrandPalette.statusWarning
        default: return StrandPalette.textSecondary
        }
    }
}

struct HomeStressMonitorCard: View {
    let value: Double?

    private var validValue: Double? {
        guard let value, value.isFinite, (0...3).contains(value) else { return nil }
        return value
    }

    var body: some View {
        NavigationLink(value: TabRoute.stress) {
            HomeMonitorCard(title: "STRESS MONITOR",
                            badge: validValue.map { String(format: "%.1f", $0) } ?? "—", symbol: nil,
                            state: validValue.map { StressBand(score: $0).title } ?? String(localized: "No reading"),
                            detail: validValue == nil ? String(localized: "Needs sensor data") : String(localized: "Daily estimate"),
                            tint: validValue.map(StressRamp.color) ?? StrandPalette.textSecondary)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("woop.home.stressMonitor")
    }
}

private struct HomeMonitorCard: View {
    let title: LocalizedStringKey
    let badge: String?
    let symbol: String?
    let state: String
    let detail: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 4) {
                Text(title).font(WhoopReferenceFont.label(10)).tracking(0.9)
                    .lineLimit(1).minimumScaleFactor(0.75)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .medium))
                    .foregroundStyle(StrandPalette.textSecondary)
            }
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6).fill(tint.opacity(0.16))
                    if let symbol { Image(systemName: symbol).font(.system(size: 16, weight: .bold)) }
                    else if let badge { Text(verbatim: badge).font(WhoopReferenceFont.metric(16)) }
                }
                .foregroundStyle(tint).frame(width: 32, height: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: state.uppercased()).font(WhoopReferenceFont.label(11)).tracking(0.5)
                        .foregroundStyle(tint).lineLimit(2)
                    Text(verbatim: detail).font(WhoopReferenceFont.body(10))
                        .foregroundStyle(StrandPalette.textSecondary).lineLimit(2)
                }
            }
        }
        .foregroundStyle(StrandPalette.textPrimary)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 102, alignment: .topLeading)
        .background(WoopHomePalette.activityCard, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
