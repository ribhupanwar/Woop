import SwiftUI
import Observation
import CoreMotion
import StrandDesign

/// An explicit trial, isolated from workout saving. Only the existing confirmed command can log a set.
struct WatchMotionSetTrialView: View {
    @Environment(WatchScoreStore.self) private var companion
    @State private var monitor = WatchMotionSetTrialMonitor()
    private var active: Bool {
        guard let state = companion.strengthWorkout, state.phase == .active else { return false }
        return state.restEndsAtTs.map { $0 <= Int(Date().timeIntervalSince1970) } ?? true
    }
    private var contextKey: String {
        guard let state = companion.strengthWorkout else { return "none" }
        return "\(state.sessionId)|\(state.revision)|\(state.phase.rawValue)|\(state.restEndsAtTs ?? 0)"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("Motion set trial").font(.headline)
                Text("Experimental · suggests a set end, not reps. Enter actual reps and weight on iPhone first.")
                    .font(.footnote)
                if let title = companion.strengthWorkout?.exerciseTitle { Text(verbatim: title) }
                Text(monitor.candidate ? "Set ended?" : monitor.running ? "Move, then rest" : "Trial stopped")
                if let error = monitor.error { Text(verbatim: error).font(.footnote) }
                if let error = companion.commandError { Text(verbatim: error).font(.footnote) }
                if monitor.candidate {
                    Button("Complete set") {
                        companion.send(.completeSet)
                        monitor.stop()
                        monitor.candidate = false
                    }.disabled(!active)
                    Button("Dismiss suggestion") { monitor.candidate = false }
                }
                Button(monitor.running ? "Stop trial" : "Start trial") {
                    if monitor.running { monitor.stop() } else { monitor.start() }
                }.disabled(!active)
                Text("No automatic save. Wrist movement can be unrelated to lifting; stationary-wrist exercises may be missed.")
                    .font(.footnote)
            }.padding()
        }
        .onChange(of: contextKey) { _, _ in
            // A phone-side edit, rest or exercise change invalidates the captured candidate.
            monitor.stop()
            monitor.candidate = false
        }
        .onDisappear { monitor.stop() }
    }
}

@Observable
@MainActor
private final class WatchMotionSetTrialMonitor {
    var running = false
    var candidate = false
    var error: String?
    @ObservationIgnored private let manager = CMMotionManager()
    @ObservationIgnored private var trial = MotionSetTrial()
    @ObservationIgnored private var timeout: Task<Void, Never>?

    func start() {
        stop()
        candidate = false
        guard manager.isDeviceMotionAvailable else {
            error = String(localized: "Motion data unavailable")
            return
        }
        error = nil
        running = true
        manager.deviceMotionUpdateInterval = 1.0 / 25
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, failure in
            let timestamp = motion?.timestamp
            let acceleration = motion.map { m in
                let a = m.userAcceleration
                return sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
            }
            let failed = failure != nil
            Task { @MainActor [weak self] in
                guard let self, self.running else { return }
                if failed {
                    self.error = String(localized: "Motion capture stopped")
                    self.stop()
                } else if let timestamp, let acceleration,
                          self.trial.ingest(timestamp: timestamp, accelerationG: acceleration) {
                    self.candidate = true
                    self.stop()
                }
            }
        }
        timeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(120))
            guard !Task.isCancelled else { return }
            self?.stop()
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        timeout?.cancel()
        timeout = nil
        running = false
        trial.reset()
    }
}
