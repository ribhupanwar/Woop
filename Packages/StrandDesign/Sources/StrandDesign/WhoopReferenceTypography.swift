import SwiftUI

/// Shared detail-screen composition, drawn independently with system typography and Woop identity.
public struct WoopMetricHero: View {
    let title: LocalizedStringKey
    let value: String
    let suffix: String
    let fraction: Double?
    let tint: Color

    public init(title: LocalizedStringKey, value: String, suffix: String = "",
                fraction: Double?, tint: Color) {
        self.title = title
        self.value = value
        self.suffix = suffix
        self.fraction = fraction
        self.tint = tint
    }

    public var body: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.12), lineWidth: 16).accessibilityHidden(true)
            if let fraction, fraction.isFinite {
                Circle().trim(from: 0, to: min(1, max(0, fraction)))
                    .stroke(tint, style: StrokeStyle(lineWidth: 16, lineCap: .butt))
                    .rotationEffect(.degrees(-90))
                    .accessibilityHidden(true)
            }
            VStack(spacing: 12) {
                Text("WOOP").font(.system(size: 17, weight: .light)).tracking(3)
                    .foregroundStyle(StrandPalette.textSecondary).accessibilityHidden(true)
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(verbatim: value).font(WhoopReferenceFont.score(60))
                    if !suffix.isEmpty { Text(verbatim: suffix).font(WhoopReferenceFont.score(36)) }
                }
                .foregroundStyle(StrandPalette.textPrimary)
                .lineLimit(1).minimumScaleFactor(0.65)
                Text(title).font(WhoopReferenceFont.label(12)).tracking(1.4)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(StrandPalette.textPrimary)
            }
            .padding(28)
        }
        .frame(width: 260, height: 260)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .accessibilityElement(children: .combine)
    }
}

public struct WoopMetricRow: View {
    let title: LocalizedStringKey
    let value: String
    let symbol: String
    let estimated: Bool

    public init(_ title: LocalizedStringKey, value: String, symbol: String, estimated: Bool = false) {
        self.title = title
        self.value = value
        self.symbol = symbol
        self.estimated = estimated
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.system(size: 19, weight: .light))
                .foregroundStyle(StrandPalette.textSecondary).frame(width: 24).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(WhoopReferenceFont.label(11)).tracking(0.8).textCase(.uppercase)
                    .foregroundStyle(StrandPalette.textPrimary).lineLimit(2)
                if estimated {
                    Text("Woop estimate").font(WhoopReferenceFont.body(10))
                        .foregroundStyle(StrandPalette.textSecondary)
                }
            }
            Spacer(minLength: 8)
            Text(verbatim: value).font(WhoopReferenceFont.score(19)).monospacedDigit()
                .foregroundStyle(StrandPalette.textPrimary).lineLimit(1)
        }
        .frame(minHeight: 48)
        .accessibilityElement(children: .combine)
    }
}

private struct WoopReferenceUIKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// The iPhone reference redesign opts in; shared macOS and legacy presentation remain separate.
    var woopReferenceUI: Bool {
        get { self[WoopReferenceUIKey.self] }
        set { self[WoopReferenceUIKey.self] = newValue }
    }
}

public struct WoopReferenceCanvas: View {
    public init() {}
    public var body: some View {
        LinearGradient(colors: [WoopHomePalette.canvasTop, WoopHomePalette.canvasBottom],
                       startPoint: .top, endPoint: .bottom)
    }
}

/// Dark Home surfaces and metric accents matched to the owner's supplied activity-dashboard reference.
/// These are independent color tokens; no third-party artwork or font files are bundled.
public enum WoopHomePalette {
    public static let canvasTop = Color(red: 0.157, green: 0.192, blue: 0.216)
    public static let canvasBottom = Color(red: 0.059, green: 0.071, blue: 0.082)
    public static let activityCard = Color(red: 0.184, green: 0.208, blue: 0.224)
    public static let activityRow = Color(red: 0.259, green: 0.278, blue: 0.290)
    public static let sleep = Color(red: 0.529, green: 0.651, blue: 0.725)
    public static let strain = Color(red: 0.263, green: 0.565, blue: 0.878)
}

/// Clean-room typographic roles for reference-matched iPhone screens.
/// WHOOP's bundled DINPro files are proprietary and are not redistributed.
/// This separate layer approximates their compact sans-serif character with system fonts,
/// leaving the app's existing StrandFont roles unchanged.
public enum WhoopReferenceFont {
    public static func score(_ size: CGFloat = 48) -> Font {
        .system(size: size, weight: .semibold, design: .default).monospacedDigit()
    }

    /// Tight tracking for large WHOOP-reference score numerals.
    public static func scoreTracking(_ size: CGFloat = 48) -> CGFloat {
        -size * 0.02
    }
    public static func heading(_ size: CGFloat = 18) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
    public static func label(_ size: CGFloat = 10) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
    public static func metric(_ size: CGFloat = 14) -> Font {
        .system(size: size, weight: .medium, design: .default).monospacedDigit()
    }
    public static func body(_ size: CGFloat = 12) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }
}


/// Compact WHOOP-reference section label, scoped to screens being ported.
public extension Text {
    func whoopReferenceOverline() -> some View {
        self.font(WhoopReferenceFont.label())
            .tracking(1.1)
            .textCase(.uppercase)
            .foregroundStyle(StrandPalette.textSecondary)
    }
}

// Compact dashboard proportions from the supplied iPhone comparison. Dynamic Type
// may grow a row beyond the minimum; these are presentation tokens only.
public enum WoopDashboardMetrics {
    public static let rowMinHeight: CGFloat = 56
    public static let horizontalPadding: CGFloat = 14
    public static let verticalPadding: CGFloat = 10
    public static let iconSize: CGFloat = 20
    public static let iconColumn: CGFloat = 24
    public static let rowGap: CGFloat = 12
    public static let valueSize: CGFloat = 22
    public static let comparisonSize: CGFloat = 10
    public static let labelSize: CGFloat = 11
    public static let cornerRadius: CGFloat = 12
}
