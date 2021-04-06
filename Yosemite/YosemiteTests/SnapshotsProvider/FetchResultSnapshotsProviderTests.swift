import XCTest
import TestKit
import CoreData
import Combine

@testable import Yosemite
import Storage

final class FetchResultSnapshotsProviderTests: XCTestCase {

    private var storageManager: MockStorageManager!

    private var cancellables = Set<AnyCancellable>()

    private var viewStorage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        cancellables.forEach {
            $0.cancel()
        }
        cancellables.removeAll()
        super.tearDown()
    }

    func test_objectWithID_returns_the_expected_immutable_object() throws {
        // Given
        let insertedAccount = insertAccount(displayName: "Reina Feil", username: "reinafeil")

        try viewStorage.obtainPermanentIDs(for: [insertedAccount])

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.displayName, ascending: true)
        )
        let provider = FetchResultSnapshotsProvider(storageManager: storageManager, query: query)

        // When
        let snapshot: FetchResultSnapshot = try waitFor { promise in
            provider.snapshot.dropFirst().sink { snapshot in
                promise(snapshot)
            }.store(in: &self.cancellables)

            try provider.start()
        }

        // Then
        let objectID = try XCTUnwrap(snapshot.itemIdentifiers.first)
        let fetchedAccount = try XCTUnwrap(provider.object(withID: objectID))
        XCTAssertEqual(fetchedAccount, insertedAccount.toReadOnly())
    }

    func test_snapshot_emits_an_empty_list_if_SnapshotsProvider_is_not_started() throws {
        // Given
        let insertedAccount = insertAccount(displayName: "Reina Feil", username: "reinafeil")

        try viewStorage.obtainPermanentIDs(for: [insertedAccount])

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.displayName, ascending: true)
        )
        let provider = FetchResultSnapshotsProvider(storageManager: storageManager, query: query)

        // When
        let snapshot: FetchResultSnapshot = waitFor { promise in
            provider.snapshot.first().sink { snapshot in
                promise(snapshot)
            }.store(in: &self.cancellables)
        }

        // Then
        assertEmpty(snapshot.itemIdentifiers)
    }

    func test_snapshot_can_emit_a_sorted_list() throws {
        // Given
        let accounts = [
            insertAccount(displayName: "Reina Feil", username: "reinafeil"),
            insertAccount(displayName: "Arvid Lowe", username: "arvidlowe"),
            insertAccount(displayName: "Lee Johns", username: "leejohns")
        ]

        try viewStorage.obtainPermanentIDs(for: accounts)

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.displayName, ascending: true)
        )
        let provider = FetchResultSnapshotsProvider(storageManager: storageManager, query: query)

        // When
        let snapshot: FetchResultSnapshot = try waitFor { promise in
            provider.snapshot.dropFirst().sink { snapshot in
                promise(snapshot)
            }.store(in: &self.cancellables)

            try provider.start()
        }

        // Then
        let expectedObjectIDs = [accounts[1].objectID, accounts[2].objectID, accounts[0].objectID]
        let actualObjectIDs = snapshot.itemIdentifiers
        XCTAssertEqual(actualObjectIDs, expectedObjectIDs)
    }

    func test_snapshot_can_emit_a_list_with_sections() throws {
        // Given
        let expectedFirstSection = [
            insertAccount(displayName: "Z", username: "Zanza"),
            insertAccount(displayName: "Z", username: "Zagato"),
            insertAccount(displayName: "Z", username: "Zabuza"),
        ]
        let expectedSecondSection = [
            insertAccount(displayName: "Y", username: "Yamada"),
            insertAccount(displayName: "Y", username: "Yajiro"),
            insertAccount(displayName: "Y", username: "Yahiko"),
            insertAccount(displayName: "Y", username: "Yagami"),
        ]

        try viewStorage.obtainPermanentIDs(for: expectedFirstSection + expectedSecondSection)

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.username, ascending: false),
            sectionNameKeyPath: #keyPath(StorageAccount.displayName)
        )
        let provider = FetchResultSnapshotsProvider(storageManager: storageManager, query: query)

        // When
        let snapshot: FetchResultSnapshot = try waitFor { promise in
            provider.snapshot.dropFirst().sink { snapshot in
                promise(snapshot)
            }.store(in: &self.cancellables)

            try provider.start()
        }

        // Then
        XCTAssertEqual(snapshot.itemIdentifiers.count, 7)
        XCTAssertEqual(snapshot.sectionIdentifiers, ["Z", "Y"])
        XCTAssertEqual(snapshot.sectionIdentifiers.count, 2)
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: "Z"), expectedFirstSection.map(\.objectID))
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: "Y"), expectedSecondSection.map(\.objectID))
    }

    func test_snapshot_can_emit_a_filtered_list() throws {
        // Given
        let expectedFirstSection = [
            insertAccount(displayName: "Z", username: "Zanza Elf"),
            insertAccount(displayName: "Z", username: "Zabuza Elf"),
        ]

        let expectedSecondSection = [
            insertAccount(displayName: "Y", username: "Yahiko Elf"),
        ]

        let excludedAccounts = [
            insertAccount(displayName: "Z", username: "Zagato Human"),
            insertAccount(displayName: "Y", username: "Yamada Human"),
            insertAccount(displayName: "Y", username: "Yajiro Human")
        ]

        try viewStorage.obtainPermanentIDs(for: expectedFirstSection + expectedSecondSection + excludedAccounts)

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.username, ascending: false),
            predicate: .init(format: "%K CONTAINS %@", #keyPath(StorageAccount.username), "Elf"),
            sectionNameKeyPath: #keyPath(StorageAccount.displayName)
        )
        let provider = FetchResultSnapshotsProvider(storageManager: storageManager, query: query)

        // When
        let snapshot: FetchResultSnapshot = try waitFor { promise in
            provider.snapshot.dropFirst().sink { snapshot in
                promise(snapshot)
            }.store(in: &self.cancellables)

            try provider.start()
        }

        // Then
        XCTAssertEqual(snapshot.itemIdentifiers.count, 3)
        XCTAssertEqual(snapshot.sectionIdentifiers.count, 2)
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: "Z"), expectedFirstSection.map(\.objectID))
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: "Y"), expectedSecondSection.map(\.objectID))
    }

    func test_snapshot_continuously_emits_values_for_structural_changes() throws {
        // Given
        let zanza = insertAccount(displayName: "Z", username: "Zanza")
        let zagato = insertAccount(displayName: "Z", username: "Zagato")
        let yamada = insertAccount(displayName: "Y", username: "Yamada")

        // Obtain permanent IDs right away so we can use the permanent object IDs for assertions
        try viewStorage.obtainPermanentIDs(for: [zanza, zagato, yamada])

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.username, ascending: false),
            sectionNameKeyPath: #keyPath(StorageAccount.displayName)
        )
        let provider = FetchResultSnapshotsProvider(storageManager: storageManager, query: query)

        var snapshots = [FetchResultSnapshot]()
        provider.snapshot.dropFirst().sink { snapshot in
            snapshots.append(snapshot)
        }.store(in: &self.cancellables)

        try provider.start()

        // When
        // Add new sections
        let xiong = insertAccount(displayName: "X", username: "Xiong")
        let wakaba = insertAccount(displayName: "W", username: "Wakaba")
        // Obtain permanent IDs right away so we can use the permanent object IDs for assertions
        try viewStorage.obtainPermanentIDs(for: [xiong, wakaba])

        // Delete a section
        viewStorage.deleteObject(yamada)

        viewStorage.saveIfNeeded()

        // Then
        XCTAssertEqual(snapshots.count, 2)

        // The first snapshot should have the first inserted accounts
        let firstSnapshot = try XCTUnwrap(snapshots.first)
        XCTAssertEqual(firstSnapshot.sectionIdentifiers, ["Z", "Y"])
        XCTAssertEqual(firstSnapshot.itemIdentifiers, [zanza.objectID, zagato.objectID, yamada.objectID])

        // The second snapshot should have 3 sections (two added, one deleted).
        let secondSnapshot = try XCTUnwrap(snapshots.last)
        XCTAssertEqual(secondSnapshot.sectionIdentifiers, ["Z", "X", "W"])
        XCTAssertEqual(secondSnapshot.itemIdentifiers(inSection: "Z"), [zanza.objectID, zagato.objectID])
        XCTAssertEqual(secondSnapshot.itemIdentifiers(inSection: "X"), [xiong.objectID])
        XCTAssertEqual(secondSnapshot.itemIdentifiers(inSection: "W"), [wakaba.objectID])
    }

    func test_snapshot_emits_a_new_snapshot_when_objects_are_updated_in_derived_storage() throws {
        // Given
        let zanza = insertAccount(displayName: "Z", username: "Zanza")
        let zagato = insertAccount(displayName: "Z", username: "Zagato")
        let yamada = insertAccount(displayName: "Y", username: "Yamada")

        try viewStorage.obtainPermanentIDs(for: [zanza, zagato, yamada])

        let derivedStorage = storageManager.writerDerivedStorage

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.username, ascending: false)
        )
        let provider = FetchResultSnapshotsProvider(storageManager: storageManager, query: query)

        var snapshots = [FetchResultSnapshot]()
        provider.snapshot.dropFirst().sink { snapshot in
            snapshots.append(snapshot)
        }.store(in: &self.cancellables)

        try provider.start()

        // When
        // This update should emit a new snapshot
        waitForExpectation { exp in
            derivedStorage.perform {
                let zanzaInDerived = derivedStorage.loadObject(ofType: StorageAccount.self, with: zanza.objectID)!
                zanzaInDerived.username = "Zanza Lockman"

                derivedStorage.saveIfNeeded()

                exp.fulfill()
            }
        }

        // Then
        XCTAssertEqual(snapshots.count, 3)

        let firstSnapshot = try XCTUnwrap(snapshots.first)
        XCTAssertEqual(firstSnapshot.itemIdentifiers, [zanza.objectID, zagato.objectID, yamada.objectID])

        // We're going to ignore the second snapshot because that's the snapshot from FRC which
        // does not _reload_ the updated items.

        // The last snapshot should be equal to the first since we only received an update.
        let lastSnapshot = try XCTUnwrap(snapshots.last)
        XCTAssertEqual(lastSnapshot.itemIdentifiers, firstSnapshot.itemIdentifiers)
    }

    func test_snapshot_does_not_emit_a_new_snapshot_when_differently_typed_objects_are_updated_in_derived_storage() throws {
        // Given
        let account = insertAccount(displayName: "Z", username: "Zanza")
        let orderStatus = insertOrderStatus(name: "accusamus")

        try viewStorage.obtainPermanentIDs(for: [account, orderStatus])

        let derivedStorage = storageManager.writerDerivedStorage

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.username, ascending: false)
        )
        let provider = FetchResultSnapshotsProvider(storageManager: storageManager, query: query)

        var snapshots = [FetchResultSnapshot]()
        // Drop the empty snapshot and the first query result snapshot
        provider.snapshot.dropFirst(2).sink { snapshot in
            snapshots.append(snapshot)
        }.store(in: &self.cancellables)

        try provider.start()

        // When
        // This update should not emit a new snapshot since the updated object is not a `StorageAccount`.
        waitForExpectation { exp in
            derivedStorage.perform {
                let orderStatusInDerived = derivedStorage.loadObject(ofType: StorageOrderStatus.self, with: orderStatus.objectID)!
                orderStatusInDerived.name = "edited orderStatus"

                derivedStorage.saveIfNeeded()

                exp.fulfill()
            }
        }

        // Then
        assertEmpty(snapshots)
    }

    func test_snapshot_does_not_emit_a_new_snapshot_when_the_updated_objects_do_not_match_the_predicate() throws {
        // Given
        let account = insertAccount(displayName: "Z", username: "Zanza")
        let excludedAccount = insertAccount(displayName: "Y", username: "Yamato")

        try viewStorage.obtainPermanentIDs(for: [account, excludedAccount])

        let derivedStorage = storageManager.writerDerivedStorage

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.username, ascending: false),
            predicate: .init(format: "%K = %@", #keyPath(StorageAccount.displayName), "Z")
        )
        let provider = FetchResultSnapshotsProvider(storageManager: storageManager, query: query)

        var snapshots = [FetchResultSnapshot]()
        // Drop the empty snapshot and the first query result snapshot
        provider.snapshot.dropFirst(2).sink { snapshot in
            snapshots.append(snapshot)
        }.store(in: &self.cancellables)

        try provider.start()

        // When
        // This update should not emit a new snapshot since the updated object is not part
        // of the query result because of the `query.predicate`.
        waitForExpectation { exp in
            derivedStorage.perform {
                let excludedAccountInDerived = derivedStorage.loadObject(ofType: StorageAccount.self,
                                                                         with: excludedAccount.objectID)!
                excludedAccountInDerived.displayName = "edited displayName"

                derivedStorage.saveIfNeeded()

                exp.fulfill()
            }
        }

        // Then
        assertEmpty(snapshots)
    }

    func test_snapshot_will_still_emit_snapshots_after_the_StorageManager_is_reset() throws {
        // Given
        let zanza = insertAccount(displayName: "Z", username: "Zanza")
        try viewStorage.obtainPermanentIDs(for: [zanza])

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.username, ascending: false)
        )
        let provider = FetchResultSnapshotsProvider(storageManager: storageManager, query: query)

        var snapshots = [FetchResultSnapshot]()
        provider.snapshot.dropFirst().sink { snapshot in
            snapshots.append(snapshot)
        }.store(in: &self.cancellables)

        try provider.start()

        // When
        // This should emit a snapshot that is just an empty list.
        storageManager.reset()

        // Inserting new objects would trigger another snapshot
        let sadako = insertAccount(displayName: "S", username: "Sadako")
        try viewStorage.obtainPermanentIDs(for: [sadako])

        viewStorage.saveIfNeeded()

        // Then
        XCTAssertEqual(snapshots.count, 3)

        let firstSnapshot = try XCTUnwrap(snapshots.first)
        XCTAssertEqual(firstSnapshot.itemIdentifiers, [zanza.objectID])

        // The second snapshot is from the reset().
        let secondSnapshot = snapshots[1]
        assertEmpty(secondSnapshot.itemIdentifiers)

        // The third snapshot is from the newly inserted objects after the reset()
        let thirdSnapshot = snapshots[2]
        XCTAssertEqual(thirdSnapshot.itemIdentifiers, [sadako.objectID])
    }
}

private extension FetchResultSnapshotsProviderTests {
    @discardableResult
    func insertAccount(displayName: String, username: String) -> StorageAccount {
        let account = storageManager.insertSampleAccount()
        account.displayName = displayName
        account.username = username
        return account
    }

    func insertOrderStatus(name: String) -> StorageOrderStatus {
        let orderStatus = viewStorage.insertNewObject(ofType: StorageOrderStatus.self)
        orderStatus.name = name
        orderStatus.slug = name
        return orderStatus
    }
}
