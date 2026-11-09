import SwiftUI
import StrandDesign

/// Compact dashboard presentation. Comparison dates remain available to VoiceOver.
/// Arrows describe a trend relative to a recorded value, not a medical assessment.
enum ReferenceMetricTrend: Equatable {
    case favorable, unfavorable, unchanged

    static func resolve(card: DashboardCard, direction: Int) -> Self {
        guard direction != 0 else { return .unchanged }
        switch card {
        case .hrv, .steps: return direction > 0 ? .favorable : .unfavorable
        case .restingHr: return direction < 0 ? .favorable : .unfavorable
        default: return .unchanged
        }
    }

    var color: Color {
        switch self {
        case .favorable: return WoopHomePalette.healthGood
        case .unfavorable: return WoopHomePalette.stressHigh
        case .unchanged: return StrandPalette.textSecondary
        }
    }
}

struct ReferenceDashboardMetricCard: View {
    struct Comparison {
        let value: String
        let day: String
        let direction: Int
    }
    let card: DashboardCard
    let value: String
    let comparison: Comparison?
    var estimated = false

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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 21, weight: .light))
                .foregroundStyle(StrandPalette.textSecondary).frame(width: 25).accessibilityHidden(true)
            Text(verbatim: title.uppercased()).font(WoopDashboardMetricStyle.label).tracking(1.1)
                .foregroundStyle(StrandPalette.textPrimary).lineLimit(2)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 7) {
                    Text(verbatim: value).font(WoopDashboardMetricStyle.value).monospacedDigit()
                        .foregroundStyle(StrandPalette.textPrimary).lineLimit(1).minimumScaleFactor(0.65)
                    if let comparison {
                        Image(systemName: comparison.direction == 0 ? "circle.fill" :
                                comparison.direction > 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                            .font(.system(size: 7)).foregroundStyle(ReferenceMetricTrend.resolve(card: card, direction: comparison.direction).color)
                    }
                }
                if let comparison {
                    Text(verbatim: comparison.value).font(WoopDashboardMetricStyle.comparison)
                        .foregroundStyle(StrandPalette.textSecondary)
                    .accessibilityLabel(Text(verbatim: "\(comparison.value), \(comparison.day)"))
                } else if estimated {
                    Text("Estimated").font(WhoopReferenceFont.body(10))
                        .foregroundStyle(StrandPalette.textSecondary)
                } else if !card.unit.isEmpty && card != .calories {
                    Text(verbatim: card.unit).font(WhoopReferenceFont.body(10))
                        .foregroundStyle(StrandPalette.textSecondary)
                }
            }
            .frame(minWidth: 54, maxWidth: 116, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, WoopDashboardMetricStyle.verticalPadding)
        .frame(maxWidth: .infinity, minHeight: WoopDashboardMetricStyle.minimumHeight)
        .background(WoopHomePalette.activityCard, in: RoundedRectangle(cornerRadius: 13))
        .accessibilityIdentifier("dashboard-metric-\(card.rawValue)")
        .accessibilityElement(children: .combine)
    }
}
