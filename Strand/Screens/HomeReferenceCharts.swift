import SwiftUI
import Charts
import StrandDesign
import StrandAnalytics
import WhoopStore

/// Uses the shared, cached stress reader and the already-loaded daily rows. No chart timers or
/// synthetic points; each missing daily reading starts a separate line segment.
struct HomeReferenceCharts: View {
    let dayKey: String
    let days: [DailyMetric]
    @EnvironmentObject private var repo: Repository
    @Environment(\.dashboardIsActive) private var active
    @State private var stress: DaytimeStress.Result?
    @State private var stressDay = ""

    private var isToday: Bool {
        // StressDayCurve is a local-midnight window, whereas dashboard sleep days roll at 04:00.
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return dayKey == formatter.string(from: Date())
    }
    private var shownStress: DaytimeStress.Result? { stressDay == dayKey ? stress : nil }
    private var lastStress: DaytimeStress.HourPoint? {
        shownStress?.timeline.last(where: { $0.level != nil })
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 18) {
                NavigationLink(value: TabRoute.stress) {
                    HStack {
                        Text("STRESS MONITOR").font(WhoopReferenceFont.label(12)).tracking(1)
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }.buttonStyle(.plain)
                HStack {
                    if let lastStress {
                        Text(Date(timeIntervalSince1970: Double(lastStress.startTs)), style: .time)
                            .font(WhoopReferenceFont.body(11)).foregroundStyle(StrandPalette.textSecondary)
                        Spacer()
                        Text("\(StressBand(score: lastStress.level ?? 0).title) \(String(format: "%.1f", lastStress.level ?? 0))")
                            .font(WhoopReferenceFont.label(13)).foregroundStyle(StressRamp.color(lastStress.level ?? 0))
                    } else {
                        Text("No recorded stress timeline for this day")
                            .font(WhoopReferenceFont.body(12)).foregroundStyle(StrandPalette.textSecondary)
                    }
                }
                if let result = shownStress, result.timeline.contains(where: { $0.level != nil }) {
                    HStack(alignment: .top, spacing: 10) {
                        VStack {
                            Text("3.0"); Spacer(); Text("2.0"); Spacer(); Text("1.0"); Spacer(); Text("0.0")
                        }.font(WhoopReferenceFont.body(9)).foregroundStyle(StrandPalette.textSecondary)
                            .frame(height: 175)
                        VStack(spacing: 8) {
                            DaytimeLoadLine(hours: result.timeline, chartHeight: 175)
                            HStack {
                                if let first = result.timeline.first {
                                    Text(Date(timeIntervalSince1970: Double(first.startTs)), style: .time)
                                }
                                Spacer()
                                if let last = result.timeline.last {
                                    Text(Date(timeIntervalSince1970: Double(last.startTs)), style: .time)
                                }
                            }.font(WhoopReferenceFont.body(9)).foregroundStyle(StrandPalette.textSecondary)
                        }
                    }
                    HStack {
                        Text("0–3 · Woop stress estimate")
                        Spacer()
                        Text("\(result.activityMaskedHours) movement hours excluded")
                    }.font(WhoopReferenceFont.body(9)).foregroundStyle(StrandPalette.textSecondary)
                }
            }
            .referenceChartCard()
            .accessibilityIdentifier("woop.dashboard.stressChart")

            VStack(alignment: .leading, spacing: 18) {
                Text("STRAIN & RECOVERY").font(WhoopReferenceFont.label(12)).tracking(1)
                weeklyChart
                HStack(spacing: 16) {
                    Label("Strain · 0–21", systemImage: "circle").foregroundStyle(WoopHomePalette.strain)
                    Label("Recovery · %", systemImage: "circle").foregroundStyle(StrandPalette.statusPositive)
                }.font(WhoopReferenceFont.body(10))
                if weeklyPoints.isEmpty {
                    Text("Charts appear when recorded scores are available.")
                        .font(WhoopReferenceFont.body(11)).foregroundStyle(StrandPalette.textSecondary)
                }
            }
            .referenceChartCard()
            .accessibilityIdentifier("woop.dashboard.strainRecoveryChart")
        }
        .task(id: "\(repo.refreshSeq)|\(dayKey)|\(active)") {
            guard active, isToday else { return }
            let requested = dayKey
            let result = await StressDayCurve.today(repo: repo,
                personalBaseline: PuffinExperiment.stressPersonalBaselineEnabled)
            guard !Task.isCancelled, requested == dayKey else { return }
            stress = result?.result
            stressDay = requested
        }
    }

    private struct Point: Identifiable {
        let id: String
        let date: Date
        let value: Double
        let plotted: Double
        let recovery: Bool
        let segment: String
        var color: Color {
            if !recovery { return WoopHomePalette.strain }
            return value < 34 ? StrandPalette.statusCritical : value < 67 ? StrandPalette.statusWarning : StrandPalette.statusPositive
        }
    }
    private var anchor: Date {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dayKey) ?? Date()
    }
    private var firstDate: Date { Calendar.current.date(byAdding: .day, value: -6, to: anchor) ?? anchor }
    private var weeklyPoints: [Point] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        var points: [Point] = []
        for recovery in [false, true] {
            var segment = 0
            for offset in 0..<7 {
                guard let date = calendar.date(byAdding: .day, value: offset, to: firstDate) else { continue }
                let key = formatter.string(from: date)
                let row = days.last(where: { $0.day == key })
                let raw = recovery ? row?.recovery : row?.strain
                guard let value = raw, value.isFinite, (0...100.0).contains(value) else {
                    segment += 1
                    continue
                }
                let shown = recovery ? value : UnitFormatter.effortValue(value, scale: .whoop)
                points.append(Point(id: "\(recovery)-\(key)", date: date, value: shown,
                                    plotted: recovery ? value * 21 / 100 : shown,
                                    recovery: recovery, segment: "\(recovery)-\(segment)"))
            }
        }
        return points
    }
    private var weeklyChart: some View {
        Chart(weeklyPoints) { point in
            LineMark(x: .value("Day", point.date), y: .value("Score", point.plotted),
                     series: .value("Segment", point.segment))
                .foregroundStyle(point.recovery ? StrandPalette.textTertiary : WoopHomePalette.strain)
            PointMark(x: .value("Day", point.date), y: .value("Score", point.plotted))
                .foregroundStyle(point.color).symbolSize(35)
                .annotation(position: point.recovery ? .bottom : .top) {
                    Text(point.recovery ? "\(Int(point.value.rounded()))%" : String(format: "%.1f", point.value))
                        .font(WhoopReferenceFont.label(9)).foregroundStyle(point.color)
                }
                .accessibilityLabel(point.recovery ? "Recovery" : "Strain")
                .accessibilityValue(point.recovery ? "\(Int(point.value.rounded())) percent" : String(format: "%.1f", point.value))
        }
        .chartYScale(domain: 0...21)
        .chartXScale(domain: firstDate...anchor)
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 7, 14, 21]) { _ in AxisGridLine(); AxisValueLabel() }
            AxisMarks(position: .trailing, values: [0, 7, 14, 21]) { value in
                AxisValueLabel { if let number = value.as(Double.self) { Text("\(Int((number / 21 * 100).rounded()))%") } }
            }
        }
        .chartXAxis { AxisMarks(values: .stride(by: .day)) { _ in AxisValueLabel(format: .dateTime.weekday(.abbreviated).day()) } }
        .frame(height: 225)
    }
}

private extension View {
    func referenceChartCard() -> some View {
        padding(16).foregroundStyle(StrandPalette.textPrimary)
            .background(WoopHomePalette.activityCard, in: RoundedRectangle(cornerRadius: 13))
    }
}
