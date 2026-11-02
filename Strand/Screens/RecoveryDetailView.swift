import SwiftUI
import StrandDesign
import StrandAnalytics
import WhoopStore

/// Dedicated Recovery detail. The score and its empty/carry states come from the same
/// presentation resolver as Today; supporting vitals are read only from that exact scored night.
struct RecoveryDetailView: View {
    @EnvironmentObject private var repo: Repository
    @State private var display: ChargeDisplay = .noData
    @State private var scoredNight: DailyMetric?
    @State private var history: [DailyMetric] = []
    @State private var loaded = false

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
                    Text("How ready is your body?")
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
        .background(StrandPalette.surfaceBase.ignoresSafeArea())
        .navigationTitle("Recovery")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: repo.refreshSeq) { await load() }
    }

    @ViewBuilder
    private var scoreCard: some View {
        NoopCard {
            VStack(spacing: 14) {
                if let score {
                    RecoveryRing(score: score, diameter: 236, lineWidth: 13,
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

    @ViewBuilder
    private func vitalSection(_ night: DailyMetric) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recovery contributors")
                .font(WhoopReferenceFont.heading(17))
                .foregroundStyle(StrandPalette.textPrimary)
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
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent recovery")
                .font(WhoopReferenceFont.heading(17))
                .foregroundStyle(StrandPalette.textPrimary)
            if !loaded {
                ProgressView().tint(StrandPalette.accent)
            } else if history.isEmpty {
                NoopCard {
                    Text("No recovery history recorded yet.")
                        .font(WhoopReferenceFont.body())
                        .foregroundStyle(StrandPalette.textSecondary)
                }
            } else {
                NoopCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(history, id: \.day) { day in
                                VStack(spacing: 5) {
                                    Capsule()
                                        .fill(StrandPalette.recoveryColor(day.recovery ?? 0))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: max(4, CGFloat(day.recovery ?? 0) * 0.92))
                                    Text(day.day.suffix(2))
                                        .font(WhoopReferenceFont.body(11))
                                        .foregroundStyle(StrandPalette.textTertiary)
                                }
                                .frame(maxWidth: .infinity, alignment: .bottom)
                                .accessibilityLabel("\(dateLabel(day.day)): \(Int((day.recovery ?? 0).rounded()))")
                            }
                        }
                        .frame(height: 112, alignment: .bottom)
                        Text("Daily scores · latest 30 recorded nights")
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
        history = Array(days.filter { $0.recovery != nil }.suffix(30))
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
