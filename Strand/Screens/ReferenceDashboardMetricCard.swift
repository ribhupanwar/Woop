import SwiftUI
import StrandDesign

/// A static, full-width dashboard row. The optional comparison names its recorded date rather than
/// implying WHOOP's proprietary baseline or a health assessment.
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 21, weight: .light))
                .foregroundStyle(StrandPalette.textSecondary).frame(width: 25).accessibilityHidden(true)
            Text(verbatim: title.uppercased()).font(WhoopReferenceFont.label(12)).tracking(1.1)
                .foregroundStyle(StrandPalette.textPrimary).lineLimit(2)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 7) {
                    Text(verbatim: value).font(WhoopReferenceFont.heading(29).bold()).monospacedDigit()
                        .foregroundStyle(StrandPalette.textPrimary).lineLimit(1).minimumScaleFactor(0.65)
                    if let comparison {
                        Image(systemName: comparison.direction == 0 ? "circle.fill" :
                                comparison.direction > 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill")
                            .font(.system(size: 7)).foregroundStyle(StrandPalette.textSecondary)
                    }
                }
                if let comparison {
                    Text(verbatim: comparison.value).font(WhoopReferenceFont.metric(12))
                        .foregroundStyle(StrandPalette.textSecondary)
                    Text(verbatim: comparison.day).font(WhoopReferenceFont.body(8))
                        .foregroundStyle(StrandPalette.textTertiary)
                } else if !card.unit.isEmpty && card != .calories {
                    Text(verbatim: card.unit).font(WhoopReferenceFont.body(10))
                        .foregroundStyle(StrandPalette.textSecondary)
                }
            }
            .frame(minWidth: 54, maxWidth: 116, alignment: .trailing)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(maxWidth: .infinity, minHeight: 64)
        .background(WoopHomePalette.activityCard, in: RoundedRectangle(cornerRadius: 13))
        .accessibilityElement(children: .combine)
    }
}
