import SwiftUI
import StrandDesign

/// Independent outline device drawing; no extracted third-party artwork.
struct ReferenceBandGlyph: View {
    var connected: Bool
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // A continuous curved strap outline, rather than a battery/ring symbol.
            Path { path in
                path.move(to: CGPoint(x: 15, y: 2))
                path.addLine(to: CGPoint(x: 9, y: 2))
                path.addCurve(to: CGPoint(x: 5, y: 30), control1: CGPoint(x: 3, y: 10), control2: CGPoint(x: 2, y: 22))
                path.addLine(to: CGPoint(x: 12, y: 32))
                path.addCurve(to: CGPoint(x: 19, y: 5), control1: CGPoint(x: 18, y: 25), control2: CGPoint(x: 20, y: 13))
                path.move(to: CGPoint(x: 7, y: 26))
                path.addLine(to: CGPoint(x: 12, y: 27))
            }
            .stroke(style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
            .frame(width: 23, height: 34)
            if connected { Circle().fill(WoopHomePalette.healthGood).frame(width: 6, height: 6) }
        }.frame(width: 25, height: 36).accessibilityHidden(true)
    }
}

struct ReferenceProfileBadge: View {
    let name: String?
    let imageData: Data?
    private var initials: String {
        let words = (name ?? "").split(whereSeparator: { $0.isWhitespace })
        guard let first = words.first?.first else { return "W" }
        let last = words.count > 1 ? words.last?.first.map(String.init) ?? "" : ""
        return (String(first) + last).uppercased()
    }
    var body: some View {
        if let imageData { ProfileAvatarView(imageData: imageData, size: 34) }
        else {
            Text(verbatim: initials).font(WhoopReferenceFont.label(13)).foregroundStyle(Color.black)
                .frame(width: 34, height: 34)
                .background(LinearGradient(colors: [WoopHomePalette.healthGood, WoopHomePalette.sleep],
                                           startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
        }
    }
}
