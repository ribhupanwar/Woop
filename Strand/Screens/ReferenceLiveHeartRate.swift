import SwiftUI
import Charts
import Combine
import StrandDesign

/// Receipt-timestamped live samples only. The shared spike-filtered readout remains the HR source.
struct ReferenceLiveHeartRate: View {
    @EnvironmentObject private var live: LiveState
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var profile: ProfileStore
    @State private var samples: [LiveHRSample] = []
    private var latest: LiveHRSample? { live.connected ? samples.last : nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("HEART RATE").font(WhoopReferenceFont.label(13)).tracking(1)
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: "heart.fill").foregroundStyle(WoopHomePalette.strain)
                    Text(latest.map { String(Int($0.bpm.rounded())) } ?? "—")
                        .font(WhoopReferenceFont.heading(48).bold()).monospacedDigit()
                    Text("BPM").font(WhoopReferenceFont.label(11)).foregroundStyle(StrandPalette.textSecondary)
                    if let latest {
                        Text("Zone \(profile.hrZoneSet.zoneNumber(forBPM: latest.bpm))")
                            .font(WhoopReferenceFont.body(12)).foregroundStyle(StrandPalette.textSecondary)
                    }
                }.frame(minWidth: 75, alignment: .leading)
                Chart(samples) { sample in
                    LineMark(x: .value("Received", sample.date), y: .value("BPM", sample.bpm))
                        .foregroundStyle(WoopHomePalette.strain)
                    if sample.id == latest?.id {
                        PointMark(x: .value("Received", sample.date), y: .value("BPM", sample.bpm))
                            .foregroundStyle(Color.white).symbolSize(35)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartYAxis(.hidden)
                .chartXAxis { AxisMarks(values: .automatic(desiredCount: 2)) { _ in
                    AxisGridLine(); AxisValueLabel(format: .dateTime.hour().minute())
                } }
                .frame(height: 150)
            }
            HStack {
                Text(live.connected ? "Connected · received samples" : "Connect your band for live HR")
                Spacer()
                if let latest { Text(latest.date, style: .time) }
            }.font(WhoopReferenceFont.body(10)).foregroundStyle(StrandPalette.textSecondary)
        }
        .foregroundStyle(StrandPalette.textPrimary)
        .accessibilityIdentifier("woop.health.liveHeartRate")
        .onReceive(live.$heartRate) { raw in
            guard live.connected, let raw, raw > 0 else { return }
            let bpm = model.bpm.flatMap { $0 > 0 ? $0 : nil } ?? raw
            guard (30...220).contains(bpm) else { return }
            let now = Date()
            samples.removeAll { now.timeIntervalSince($0.date) > 180 }
            samples.append(LiveHRSample(date: now, bpm: Double(bpm)))
            if samples.count > 180 { samples.removeFirst(samples.count - 180) }
        }
        .onChangeCompat(of: live.connected) { connected in if !connected { samples = [] } }
    }
}
