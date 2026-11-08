import SwiftUI
import StrandDesign

/// Firmware status only. A DFU opcode is not a validated firmware update implementation.
struct BandFirmwareView: View {
    @EnvironmentObject private var live: LiveState
    var body: some View {
        ScreenScaffold(title: "Band firmware", lazy: true) {
            NoopCard {
                VStack(alignment: .leading, spacing: 14) {
                    Label("Installed version", systemImage: "cpu")
                        .font(WhoopReferenceFont.label(13))
                    Text(live.connected ? (live.strapFirmware ?? "Waiting for version reply") : "Connect your band to read its version")
                        .font(WhoopReferenceFont.heading(22))
                    Text("Direct firmware updates are not implemented in Woop. Update your band using the official WHOOP app, then reconnect here.")
                        .font(WhoopReferenceFont.body(13)).foregroundStyle(StrandPalette.textSecondary)
                    Text("A verified updater requires an official firmware source, signature checks and a tested recovery flow. This screen sends no firmware or DFU commands.")
                        .font(WhoopReferenceFont.body(12)).foregroundStyle(StrandPalette.textSecondary)
                    Link("WHOOP support", destination: URL(string: "https://support.whoop.com/")!)
                }
            }
        }
    }
}
