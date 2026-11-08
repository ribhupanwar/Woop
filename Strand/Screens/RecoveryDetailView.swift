import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

/// Presentation windows use civil day keys, independent of the phone's current UTC offset.
enum RecoveryHistoryRange: Int, CaseIterable {
    case week = 7
    case month = 30

    func dayKeys(endingOn day: String) -> [String] {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyyy-MM-dd"
        parser.isLenient = false
        guard let end = parser.date(from: day), parser.string(from: end) == day else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = parser.timeZone
        return (0..<rawValue).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: end).map { parser.string(from: $0) }
        }
    }
}

/// Dedicated Recovery detail. The score and its empty/carry states come from the same
/// presentation resolver as Today; supporting vitals are read only from that exact scored night.
struct RecoveryDetailView: View {
    @EnvironmentObject private var repo: Repository
    @State private var display: ChargeDisplay = .noData
    @State private var scoredNight: DailyMetric?
    @State private var history: [DailyMetric] = []
    @State private var loaded = false
    @State private var historyRange: RecoveryHistoryRange = .week
    @State private var historyEndDay = ""
    @Environment(\.woopReferenceUI) private var referenceUI

    private var score: Double? { display.pct }

    /// WHOOP's Recovery contributor set includes sleep performance. Resolve it on the exact
    /// scored-night day with the same imported-first/on-device-composite rule used by Sleep and Today.
    private var sleepPerformance: Double? {
        guard let night = scoredNight else { return nil }
        return DashboardRestScore.value(day: night.day, days: repo.days,
                                        importedSleep: repo.importedSleep)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("RECOVERY").whoopReferenceOverline()
                    Text(scoredNight.map { dateLabel($0.day) } ?? String(localized: "How ready is your body?"))
                        .font(WhoopReferenceFont.heading(22))
                        .foregroundStyle(StrandPalette.textPrimary)
                    Text("Based on your recorded overnight recovery data.")
                        .font(WhoopReferenceFont.body())
                        .foregroundStyle(StrandPalette.textSecondary)
                }

                scoreCard

                if let night = scoredNight {
                    vitalSection(night)
                } else {
                    NoopCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Recovery contributors")
                                .font(WhoopReferenceFont.heading(16))
                                .foregroundStyle(StrandPalette.textPrimary)
                            Text("HRV, resting heart rate, respiratory rate and sleep performance appear when that scored night has matching readings.")
                                .font(WhoopReferenceFont.body(12))
                                .foregroundStyle(StrandPalette.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                historySection
            }
            .padding(NoopMetrics.screenPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {
            if referenceUI { WoopReferenceCanvas().ignoresSafeArea() }
            else { StrandPalette.surfaceBase.ignoresSafeArea() }
        }
        .navigationTitle("Recovery")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .task(id: repo.refreshSeq) { await load() }
        .refreshable { await repo.refresh() }
    }

    @ViewBuilder
    private var scoreCard: some View {
        if referenceUI, let score {
            VStack(spacing: 0) {
                WoopMetricHero(title: "RECOVERY", value: "\(Int(score.rounded()))", suffix: "%",
                               fraction: score / 100, tint: WoopHomePalette.recovery(score))
                if let caption = display.carriedCaption {
                    Text(caption).font(WhoopReferenceFont.body(12))
                        .foregroundStyle(StrandPalette.textSecondary)
                }
            }
        } else {
            NoopCard {
                VStack(spacing: 14) {
                    if let score {
                        RecoveryRing(score: score, diameter: 214, lineWidth: 13,
                                     showsWordmark: false, showsHover: false,
                                     valueFormat: { "Recovery \(Int($0.rounded()))" })
                        // RecoveryRing already renders the score's state word inside its gauge.
                        if let caption = display.carriedCaption {
                            Text(caption)
                                .font(WhoopReferenceFont.body(12))
                                .foregroundStyle(StrandPalette.textSecondary)
                                .multilineTextAlignment(.center)
                        } else if let day = scoredNight?.day {
                            Text(dateLabel(day))
                                .font(WhoopReferenceFont.body(12))
                                .foregroundStyle(StrandPalette.textTertiary)
                        }
                    } else {
                        Image(systemName: display == .noData ? "moon.zzz" : "waveform.path.ecg")
                            .font(.system(size: 30, weight: .light))
                            .foregroundStyle(StrandPalette.textTertiary)
                        Text(display.stateLabel)
                            .font(WhoopReferenceFont.heading(22))
                            .foregroundStyle(StrandPalette.textPrimary)
                        if case .calibrating(let nights) = display {
                            Text("\(nights) of \(Baselines.minNightsSeed) nights")
                                .font(WhoopReferenceFont.body(12))
                                .foregroundStyle(StrandPalette.textSecondary)
                        } else {
                            Text("A recovery score will appear when a valid scored night is available.")
                                .font(WhoopReferenceFont.body(12))
                                .foregroundStyle(StrandPalette.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
        }
    }

    @ViewBuilder
    private func vitalSection(_ night: DailyMetric) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recovery contributors")
                .font(WhoopReferenceFont.heading(17))
                .foregroundStyle(StrandPalette.textPrimary)
            if referenceUI {
                NoopCard {
                    VStack(spacing: 0) {
                        WoopMetricRow("Heart rate variability", value: night.avgHrv.map { "\(Int($0.rounded())) ms" } ?? "—", symbol: "waveform.path.ecg")
                        Divider().overlay(Color.white.opacity(0.08))
                        WoopMetricRow("Resting heart rate", value: night.restingHr.map { "\($0) bpm" } ?? "—", symbol: "heart")
                        Divider().overlay(Color.white.opacity(0.08))
                        WoopMetricRow("Respiratory rate", value: night.respRateBpm.map { String(format: "%.1f", $0) } ?? "—", symbol: "wind")
                        Divider().overlay(Color.white.opacity(0.08))
                        WoopMetricRow("Sleep performance", value: sleepPerformance.map { "\(Int($0.rounded()))%" } ?? "—", symbol: "moon.zzz")
                    }
                }
            } else {
                HStack(spacing: 10) {
                    vitalCard(title: "HRV", value: night.avgHrv.map { "\(Int($0.rounded()))" } ?? "—",
                              unit: "ms", symbol: "waveform.path.ecg")
                    vitalCard(title: "Resting HR", value: night.restingHr.map(String.init) ?? "—",
                              unit: "bpm", symbol: "heart")
                }
                HStack(spacing: 10) {
                    vitalCard(title: "Respiratory rate",
                              value: night.respRateBpm.map { String(format: "%.1f", $0) } ?? "—",
                              unit: "breaths/min", symbol: "wind")
                    vitalCard(title: "Sleep performance",
                              value: sleepPerformance.map { "\(Int($0.rounded()))" } ?? "—",
                              unit: "%", symbol: "moon.zzz")
                }
            }
            Text("All values shown are from \(dateLabel(night.day)) and belong to the same scored night.")
                .font(WhoopReferenceFont.body(11))
                .foregroundStyle(StrandPalette.textTertiary)
        }
    }

    private func vitalCard(title: String, value: String, unit: String, symbol: String) -> some View {
        NoopCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(title, systemImage: symbol)
                    .font(WhoopReferenceFont.body(12))
                    .foregroundStyle(StrandPalette.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(value)
                        .font(WhoopReferenceFont.score(28))
                        .foregroundStyle(StrandPalette.textPrimary)
                    Text(unit)
                        .font(WhoopReferenceFont.body(11))
                        .foregroundStyle(StrandPalette.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private var historySection: some View {
        let dayKeys = historyRange.dayKeys(endingOn: historyEndDay)
        let scores = Dictionary(history.compactMap { row -> (String, Double)? in
            guard let score = row.recovery, score.isFinite, (0...100).contains(score) else { return nil }
            return (row.day, score)
        }, uniquingKeysWith: { _, last in last })
        let hasScores = dayKeys.contains { scores[$0] != nil }
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recovery trend")
                    .font(WhoopReferenceFont.heading(17))
                    .foregroundStyle(StrandPalette.textPrimary)
                Spacer(minLength: 8)
                Picker("Recovery history range", selection: $historyRange) {
                    Text("Week").tag(RecoveryHistoryRange.week)
                    Text("Month").tag(RecoveryHistoryRange.month)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 164)
            }
            if !loaded {
                ProgressView().tint(StrandPalette.accent)
            } else if !hasScores {
                NoopCard {
                    Text("No recovery scores recorded in this period.")
                        .font(WhoopReferenceFont.body())
                        .foregroundStyle(StrandPalette.textSecondary)
                }
            } else {
                NoopCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(dayKeys, id: \.self) { day in
                                VStack(spacing: 5) {
                                    if let score = scores[day] {
                                        Capsule()
                                            .fill(StrandPalette.recoveryColor(score))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: max(4, CGFloat(score) * 0.92))
                                    } else {
                                        // Missing days retain their place; they are never zero scores.
                                        Color.clear.frame(height: 4)
                                    }
                                    if historyRange == .week {
                                        Text(day.suffix(2))
                                            .font(WhoopReferenceFont.body(11))
                                            .foregroundStyle(StrandPalette.textTertiary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .bottom)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(dateLabel(day))
                                .accessibilityValue(scores[day].map { String(Int($0.rounded())) }
                                                    ?? String(localized: "No data"))
                            }
                        }
                        .frame(height: 112, alignment: .bottom)
                        Text(historyRange == .week ? "Daily scores · last 7 days · gaps mean no data"
                             : "Daily scores · last 30 days · gaps mean no data")
                            .font(WhoopReferenceFont.body(11))
                            .foregroundStyle(StrandPalette.textTertiary)
                    }
                }
            }
        }
    }

    @MainActor
    private func load() async {
        let days = repo.days
        let todayKey = repo.today?.day ?? Repository.logicalDayKey(Date())
        let todayRow = repo.today ?? days.last(where: { $0.day == todayKey })
        let resolved = ChargeDisplay.resolve(days: days, displayDay: todayRow,
                                             selectedDayKey: todayKey, isToday: true)
        let night: DailyMetric?
        switch resolved {
        case .scored:
            night = todayRow?.recovery == nil ? nil : todayRow
        case .carried:
            night = TodayView.lastScoredRecoveryDay(
                days: days, selectedDayKey: todayRow?.day ?? todayKey,
                isToday: true, todayScored: false, isCalibrating: false)
        case .calibrating, .noData:
            night = nil
        }
        display = resolved
        scoredNight = night
        historyEndDay = todayKey
        let historyDays = Set(RecoveryHistoryRange.month.dayKeys(endingOn: todayKey))
        history = days.filter { historyDays.contains($0.day) }
        loaded = true
    }

    private func dateLabel(_ day: String) -> String {
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: day) else { return day }
        let output = DateFormatter()
        output.locale = AppLanguage.activeLocale
        output.timeZone = TimeZone(secondsFromGMT: 0)
        output.dateFormat = "d MMM yyyy"
        return output.string(from: date)
    }
}
