import SwiftUI

/// Clean-room typographic roles for reference-matched iPhone screens.
/// WHOOP's bundled DINPro files are proprietary and are not redistributed.
/// This separate layer approximates their compact sans-serif character with system fonts,
/// leaving the app's existing StrandFont roles unchanged.
public enum WhoopReferenceFont {
    public static func score(_ size: CGFloat = 54) -> Font {
        .system(size: size, weight: .semibold, design: .default).monospacedDigit()
    }
    public static func heading(_ size: CGFloat = 20) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
    public static func label(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
    public static func metric(_ size: CGFloat = 16) -> Font {
        .system(size: size, weight: .medium, design: .default).monospacedDigit()
    }
    public static func body(_ size: CGFloat = 14) -> Font {
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
