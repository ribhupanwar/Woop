import XCTest
import GRDB
@testable import WhoopStore

final class DeviceRegistryStoreTests: XCTestCase {
    private func makeDB() throws -> DatabaseQueue {
        let dbq = try DatabaseQueue()
        try WhoopStore.makeMigrator().migrate(dbq)   // applies through v15, seeds 'my-whoop' active
        return dbq
    }

    func testSeededWhoopIsActive() throws {
        let store = DeviceRegistryStore(dbQueue: try makeDB())
        let devices = try store.all()
        XCTAssertEqual(devices.count, 1)
        XCTAssertEqual(devices.first?.id, "my-whoop")
        XCTAssertEqual(try store.activeDeviceId(), "my-whoop")
    }

    func testSetActiveEnforcesSingleActive() throws {
        let store = DeviceRegistryStore(dbQueue: try makeDB())
        try store.add(PairedDevice(id: "polar-1", brand: "Polar", model: "H10", sourceKind: .liveBLE,
                                   capabilities: [.hr, .hrv], status: .paired, addedAt: 1, lastSeenAt: 1))
        try store.setActive("polar-1")
        XCTAssertEqual(try store.activeDeviceId(), "polar-1")
        let statuses = Dictionary(uniqueKeysWithValues: try store.all().map { ($0.id, $0.status) })
        XCTAssertEqual(statuses["polar-1"], .active)
        XCTAssertEqual(statuses["my-whoop"], .paired)   // the previously-active device was demoted
        XCTAssertEqual(try store.all().filter { $0.status == .active }.count, 1)  // I1
    }

    func testArchiveKeepsRowAndClearsActive() throws {
        let store = DeviceRegistryStore(dbQueue: try makeDB())
        try store.archive("my-whoop")
        XCTAssertEqual(try store.all().first?.status, .archived)   // I4: row kept
        XCTAssertNil(try store.activeDeviceId())
    }

    func testSeededWhoopHasNilPeripheralId() throws {
        // v16 applies cleanly: the seeded my-whoop row exists with peripheralId nil (it connects to
        // "any WHOOP" today; it adopts its peripheral id later).
        let store = DeviceRegistryStore(dbQueue: try makeDB())
        let seeded = try store.all().first
        XCTAssertEqual(seeded?.id, "my-whoop")
        XCTAssertNil(seeded?.peripheralId)
    }

    func testPeripheralIdRoundTripsThroughAddAndAll() throws {
        let store = DeviceRegistryStore(dbQueue: try makeDB())
        let pid = "8E1A2B3C-4D5E-6F70-8192-A3B4C5D6E7F8"
        try store.add(PairedDevice(id: "whoop-\(pid)", brand: "WHOOP", model: "WHOOP 5.0",
                                   peripheralId: pid, sourceKind: .liveBLE,
                                   capabilities: [.hr, .hrv], status: .paired, addedAt: 10, lastSeenAt: 10))
        let fetched = try store.all().first { $0.id == "whoop-\(pid)" }
        XCTAssertEqual(fetched?.peripheralId, pid)
    }

    func testSetPeripheralIdUpdatesIt() throws {
        let store = DeviceRegistryStore(dbQueue: try makeDB())
        XCTAssertNil(try store.all().first { $0.id == "my-whoop" }?.peripheralId)
        let pid = "11111111-2222-3333-4444-555555555555"
        try store.setPeripheralId("my-whoop", peripheralId: pid)
        XCTAssertEqual(try store.all().first { $0.id == "my-whoop" }?.peripheralId, pid)
        // passing nil un-adopts it
        try store.setPeripheralId("my-whoop", peripheralId: nil)
        XCTAssertNil(try store.all().first { $0.id == "my-whoop" }?.peripheralId)
    }

    func testDeviceForPeripheralIdFindsIt() throws {
        let store = DeviceRegistryStore(dbQueue: try makeDB())
        let pid = "ABCDEF01-2345-6789-ABCD-EF0123456789"
        XCTAssertNil(try store.device(forPeripheralId: pid))   // none adopted yet
        try store.setPeripheralId("my-whoop", peripheralId: pid)
        XCTAssertEqual(try store.device(forPeripheralId: pid)?.id, "my-whoop")
        XCTAssertNil(try store.device(forPeripheralId: "no-such-peripheral"))
    }

    func testDayOwnershipUpsertAndRead() throws {
        let store = DeviceRegistryStore(dbQueue: try makeDB())
        try store.setDayOwner(day: "2026-06-15", deviceId: "my-whoop", locked: true)
        XCTAssertEqual(try store.dayOwner("2026-06-15")?.deviceId, "my-whoop")
        XCTAssertEqual(try store.dayOwner("2026-06-15")?.locked, true)
        XCTAssertNil(try store.dayOwner("2000-01-01"))
        // upsert: re-writing the same day replaces the owner + locked flag (no duplicate row)
        try store.setDayOwner(day: "2026-06-15", deviceId: "polar-1", locked: false)
        XCTAssertEqual(try store.dayOwner("2026-06-15")?.deviceId, "polar-1")
        XCTAssertEqual(try store.dayOwner("2026-06-15")?.locked, false)
    }
}
