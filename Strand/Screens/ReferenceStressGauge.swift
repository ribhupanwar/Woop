import SwiftUI
import StrandDesign

/// Reference-shaped 0–3 scale around the existing daily stress estimate, not a WHOOP measurement.
struct ReferenceStressGauge: View {
    let score: Double
    var asOf: Date? = nil

    private var fraction: Double { min(1, max(0, score / 3)) }
    private var ramp: AngularGradient {
        AngularGradient(colors: [WoopHomePalette.stressLow, WoopHomePalette.healthGood, WoopHomePalette.stressHigh],
                        center: .center, startAngle: .degrees(0), endAngle: .degrees(270))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle().trim(from: 0, to: 0.75)
                    .stroke(ramp.opacity(0.20), style: StrokeStyle(lineWidth: 17, lineCap: .round))
                    .rotationEffect(.degrees(135)).accessibilityHidden(true)
                Circle().trim(from: 0, to: 0.75)
                    .stroke(ramp, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(135)).accessibilityHidden(true)
                Capsule().fill(Color.white).frame(width: 5, height: 23)
                    .offset(y: -130).rotationEffect(.degrees(225 + fraction * 270))
                    .accessibilityHidden(true)
                VStack(spacing: 12) {
                    Text(String(format: "%.1f", score)).font(WhoopReferenceFont.score(54))
                        .foregroundStyle(StrandPalette.textPrimary)
                    Text(StressBand(score: score).title).font(WhoopReferenceFont.label(14)).tracking(1.4)
                        .foregroundStyle(StressRamp.labelColor(score))
                    Text("Daily estimate").font(WhoopReferenceFont.body(11))
                        .foregroundStyle(StrandPalette.textSecondary)
                    if let asOf {
                        Text(asOf.formatted(date: .abbreviated, time: .omitted))
                            .font(WhoopReferenceFont.body(11)).foregroundStyle(StrandPalette.textTertiary)
                    }
                }
            }
            .frame(width: 260, height: 260)
            HStack {
                Text("0.0")
                Spacer()
                Text("3.0")
            }
            .font(WhoopReferenceFont.label(11)).foregroundStyle(StrandPalette.textTertiary)
            .frame(width: 220)
            .offset(y: -20)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 18)
        .accessibilityElement(children: .combine)
    }
}
