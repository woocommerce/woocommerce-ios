import XCTest
import CoreData
import Combine

@testable import Yosemite

final class FetchResultSnapshotsProviderTests: XCTestCase {

    private var storageManager: MockupStorageManager!

    override func setUp() {
        super.setUp()
        storageManager = MockupStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    @available(iOS 13.0, *)
    func test_it_works() throws {
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
            var cancellable: AnyCancellable?
            cancellable = provider.snapshot.first().sink { snapshot in
                done(snapshot)
                cancellable?.cancel()
            }

            try provider.start()
        }

        // Then
        let expectedObjectIDs = [accounts[1].objectID, accounts[2].objectID, accounts[0].objectID]
        let actualObjectIDs = snapshot.itemIdentifiers
        XCTAssertEqual(expectedObjectIDs, actualObjectIDs)
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
}
