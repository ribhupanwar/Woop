import Foundation

/// Keeps the ordering between the Health import and the cache that feeds Today.
/// HealthKit writes to the local store first; only then is the visible repository refreshed.
@MainActor
enum HealthSyncRefreshCoordinator {
    static func run(sync: () async -> Void, refresh: () async -> Void) async {
        await sync()
        await refresh()
    }
}

/// One user refresh owns device requests and visible cache updates. Repeated pulls join that work
/// rather than queueing more history imports while the first one is still running.
@MainActor
final class DashboardRefreshCoordinator {
    private var inFlight: Task<Void, Never>?

    func run(requestStrapSync: @escaping @MainActor () -> Void,
             refreshLocal: @escaping @MainActor () async -> Void,
             syncHealth: @escaping @MainActor () async -> Void) async {
        if let inFlight { await inFlight.value; return }
        let task = Task { @MainActor in
            requestStrapSync()
            await refreshLocal()
            await syncHealth()
            await refreshLocal()
        }
        inFlight = task
        await task.value
        inFlight = nil
    }
}
