import SwiftUI

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
