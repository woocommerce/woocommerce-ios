import XCTest
import TestKit
import CoreData
import Combine

@testable import Yosemite
import Storage

@available(iOS 13.0, *)
final class FetchResultSnapshotsProviderTests: XCTestCase {

    private var storageManager: MockupStorageManager!

    private var cancellables = Set<AnyCancellable>()

    private var viewStorage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockupStorageManager()
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
        let snapshot: FetchResultSnapshot = try waitFor { promise in
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
}

@available(iOS 13.0, *)
private extension FetchResultSnapshotsProviderTests {
    @discardableResult
    func insertAccount(displayName: String, username: String) -> StorageAccount {
        let account = storageManager.insertSampleAccount()
        account.displayName = displayName
        account.username = username
        return account
    }
}
