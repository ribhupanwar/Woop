import SwiftUI
import StrandDesign

/// A compact dashboard row. Comparison dates remain available to accessibility;
/// colors describe the direction for this metric, rather than an overall health score.
struct ReferenceDashboardMetricCard: View {
    struct Comparison {
        let value: String
        let day: String
        let direction: Int
    }
    let card: DashboardCard
    let value: String
    let comparison: Comparison?

    private var title: String {
        switch card {
        case .hrv: return String(localized: "Heart rate variability")
        case .restingHr: return String(localized: "Resting heart rate")
        case .vo2max: return "VO₂ Max"
        default: return card.title
        }
    }
    private var icon: String {
        switch card {
        case .restingHr: return "heart"
        case .respiratory: return "lungs"
        case .steps: return "shoeprints.fill"
        case .calories: return "flame"
        default: return card.icon
        }
    }

    private func trendTint(_ direction: Int) -> Color {
        switch DashboardTrendMeaning.resolve(card: card, direction: direction) {
        case .favorable: return StrandPalette.statusPositive
        case .unfavorable: return StrandPalette.statusWarning
        case .neutral: return StrandPalette.textSecondary
        }
    }

    var body: some View {
        HStack(spacing: WoopDashboardMetrics.rowGap) {
            Image(systemName: icon).font(.system(size: WoopDashboardMetrics.iconSize, weight: .light))
                .foregroundStyle(StrandPalette.textSecondary).frame(width: WoopDashboardMetrics.iconColumn).accessibilityHidden(true)
            Text(verbatim: title.uppercased()).font(WhoopReferenceFont.label(WoopDashboardMetrics.labelSize)).tracking(1.1)
                .foregroundStyle(StrandPalette.textPrimary).lineLimit(2)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 1) {
                HStack(spacing: 7) {
                    Text(verbatim: value).font(WhoopReferenceFont.score(WoopDashboardMetrics.valueSize)).monospacedDigit()
                        .foregroundStyle(StrandPalette.textPrimary).lineLimit(1).minimumScaleFactor(0.65)
                    if let comparison {
                        Image(systemName: comparison.direction == 0 ? "circle.fill" :
                                comparison.direction > 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                            .font(.system(size: 7)).foregroundStyle(trendTint(comparison.direction))
                    }
                }
                if let comparison {
                    Text(verbatim: comparison.value).font(WhoopReferenceFont.metric(WoopDashboardMetrics.comparisonSize))
                        .foregroundStyle(StrandPalette.textSecondary)
                } else if !card.unit.isEmpty && card != .calories {
                    Text(verbatim: card.unit).font(WhoopReferenceFont.body(10))
                        .foregroundStyle(StrandPalette.textSecondary)
                }
            }
            .frame(minWidth: 54, maxWidth: 116, alignment: .trailing)
        }
        .padding(.horizontal, WoopDashboardMetrics.horizontalPadding)
        .padding(.vertical, WoopDashboardMetrics.verticalPadding)
        .frame(maxWidth: .infinity, minHeight: WoopDashboardMetrics.rowMinHeight)
        .background(WoopHomePalette.activityCard, in: RoundedRectangle(cornerRadius: WoopDashboardMetrics.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text(verbatim: comparison?.day ?? ""))
    }
}

// Analysis migration required: no. Direction colors do not change values or scoring.
enum DashboardTrendMeaning: Equatable {
    case favorable, unfavorable, neutral

    static func resolve(card: DashboardCard, direction: Int) -> Self {
        guard direction != 0 else { return .neutral }
        switch card {
        case .hrv, .vo2max, .steps, .stepsAverage30, .sleep:
            return direction > 0 ? .favorable : .unfavorable
        case .restingHr, .fitnessAge, .vitality, .stress:
            return direction < 0 ? .favorable : .unfavorable
        // More calories, weight, oxygen or temperature is not inherently better.
        // Range-based metrics need a personal target before assigning a color.
        default:
            return .neutral
        }
    }
}
