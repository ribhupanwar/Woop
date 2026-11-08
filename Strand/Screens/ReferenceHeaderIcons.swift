import SwiftUI
import StrandDesign

/// Independent outline device drawing; no extracted third-party artwork.
struct ReferenceBandGlyph: View {
    var connected: Bool
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 1) {
                RoundedRectangle(cornerRadius: 2).stroke(lineWidth: 1).frame(width: 10, height: 5)
                RoundedRectangle(cornerRadius: 4).stroke(lineWidth: 1.5).frame(width: 15, height: 20)
                RoundedRectangle(cornerRadius: 2).stroke(lineWidth: 1).frame(width: 10, height: 5)
            }.rotationEffect(.degrees(8)).padding(3)
            if connected { Circle().fill(StrandPalette.statusPositive).frame(width: 6, height: 6) }
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
                .background(LinearGradient(colors: [StrandPalette.statusPositive, WoopHomePalette.sleep],
                                           startPoint: .topLeading, endPoint: .bottomTrailing), in: Circle())
        }
    }
}
