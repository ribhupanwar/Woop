import XCTest
@testable import Strand

@MainActor
final class HealthSyncRefreshCoordinatorTests: XCTestCase {
    func testRepeatedDashboardPullsJoinOneSyncAndPublishBeforeAndAfterHealth() async {
        let coordinator = DashboardRefreshCoordinator()
        let healthStarted = expectation(description: "Health import started")
        let secondStarted = expectation(description: "second pull joined")
        var events: [String] = []
        var releaseHealth: CheckedContinuation<Void, Never>?
        let first = Task { @MainActor in
            await coordinator.run(requestStrapSync: { events.append("strap") },
                                  refreshLocal: { events.append("cache") }, syncHealth: {
                events.append("health")
                await withCheckedContinuation { continuation in
                    releaseHealth = continuation
                    healthStarted.fulfill()
                }
            })
        }
        await fulfillment(of: [healthStarted], timeout: 2)
        let second = Task { @MainActor in
            secondStarted.fulfill()
            await coordinator.run(requestStrapSync: { events.append("duplicate strap") },
                                  refreshLocal: { events.append("duplicate cache") },
                                  syncHealth: { events.append("duplicate health") })
        }
        await fulfillment(of: [secondStarted], timeout: 2)
        releaseHealth?.resume()
        await first.value
        await second.value
        XCTAssertEqual(events, ["strap", "cache", "health", "cache"])
    }

    func testRefrescaElRepositorioDespuesDeSincronizarHealthKit() async {
        var eventos: [String] = []

        await HealthSyncRefreshCoordinator.run(
            sync: { eventos.append("sync") },
            refresh: { eventos.append("refresh") }
        )

        XCTAssertEqual(eventos, ["sync", "refresh"])
    }
}
