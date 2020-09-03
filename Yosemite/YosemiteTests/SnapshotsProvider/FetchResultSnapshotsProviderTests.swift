import XCTest
import TestKit
import CoreData
import Combine

@testable import Yosemite

@available(iOS 13.0, *)
final class FetchResultSnapshotsProviderTests: XCTestCase {

    private var storageManager: MockupStorageManager!

    private var cancellables = Set<AnyCancellable>()

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

    func test_snapshot_emits_an_empty_list_if_SnapshotsProvider_is_not_started() throws {
        // Given
        insertAccount(displayName: "Reina Feil", username: "reinafeil")

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.displayName, ascending: true)
        )
        let provider = FetchResultSnapshotsProvider(storage: storageManager.viewStorage, query: query)

        // When
        let snapshot: FetchResultSnapshotsProvider<StorageAccount>.Snapshot = try waitFor { done in
            provider.snapshot.first().sink { snapshot in
                done(snapshot)
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

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.displayName, ascending: true)
        )
        let provider = FetchResultSnapshotsProvider(storage: storageManager.viewStorage, query: query)

        // When
        let snapshot: FetchResultSnapshotsProvider<StorageAccount>.Snapshot = try waitFor { done in
            provider.snapshot.dropFirst().sink { snapshot in
                done(snapshot)
            }.store(in: &self.cancellables)

            try provider.start()
        }

        // Then
        let expectedObjectIDs = [accounts[1].objectID, accounts[2].objectID, accounts[0].objectID]
        let actualObjectIDs = snapshot.itemIdentifiers
        XCTAssertEqual(expectedObjectIDs, actualObjectIDs)
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

        let query = FetchResultSnapshotsProvider<StorageAccount>.Query(
            sortDescriptor: .init(keyPath: \StorageAccount.username, ascending: false),
            sectionNameKeyPath: #keyPath(StorageAccount.displayName)
        )
        let provider = FetchResultSnapshotsProvider(storage: storageManager.viewStorage, query: query)

        // When
        let snapshot: FetchResultSnapshotsProvider<StorageAccount>.Snapshot = try waitFor { done in
            provider.snapshot.dropFirst().sink { snapshot in
                done(snapshot)
            }.store(in: &self.cancellables)

            try provider.start()
        }

        // Then
        XCTAssertEqual(snapshot.sectionIdentifiers.count, 2)
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: snapshot.sectionIdentifiers[0]),
                       expectedFirstSection.map(\.objectID))
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: snapshot.sectionIdentifiers[1]),
                       expectedSecondSection.map(\.objectID))
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
