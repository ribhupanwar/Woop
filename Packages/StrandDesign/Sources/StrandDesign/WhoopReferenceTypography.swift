import SwiftUI

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
