import XCTest
import Yosemite
@testable import WooCommerce
import protocol Storage.StorageManagerType
import protocol Storage.StorageType

final class InboxDashboardCardViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 134

    /// Mock Storage: InMemory
    private var storageManager: StorageManagerType!

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    @MainActor
    func test_syncingData_is_updated_correctly() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = InboxDashboardCardViewModel(siteID: sampleSiteID, stores: stores)
        XCTAssertFalse(viewModel.syncingData)

        // When
        stores.whenReceivingAction(ofType: InboxNotesAction.self) { action in
            switch action {
            case let .loadAllInboxNotes(_, _, _, _, _, _, completion):
                XCTAssertTrue(viewModel.syncingData)
                completion(.success([InboxNote.fake().copy(siteID: self.sampleSiteID)]))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        XCTAssertFalse(viewModel.syncingData)
    }

    @MainActor
    func test_syncingError_is_updated_correctly() async {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = InboxDashboardCardViewModel(siteID: sampleSiteID, stores: stores)
        XCTAssertNil(viewModel.syncingError)
        let error = NSError(domain: "test", code: 500)

        // When
        stores.whenReceivingAction(ofType: InboxNotesAction.self) { action in
            switch action {
            case let .loadAllInboxNotes(_, _, _, _, _, _, completion):
                completion(.failure(error))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.syncingError as? NSError, error)
    }

    @MainActor
    func test_noteRowViewModels_match_loaded_notes() async {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let note = InboxNote.fake().copy(siteID: sampleSiteID)
        stores.whenReceivingAction(ofType: InboxNotesAction.self) { action in
            guard case let .loadAllInboxNotes(_, _, _, _, _, _, completion) = action else {
                return
            }
            self.insertInboxNotes([note])
            completion(.success([note]))
        }
        let viewModel = InboxDashboardCardViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // When
        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.noteRowViewModels.first, .init(note: note))
    }
}

extension InboxDashboardCardViewModelTests {
    func insertInboxNotes(_ readOnlyInboxNotes: [InboxNote]) {
        readOnlyInboxNotes.forEach { inboxNote in
            let newInboxNote = storage.insertNewObject(ofType: StorageInboxNote.self)
            newInboxNote.update(with: inboxNote)
        }
        storage.saveIfNeeded()
    }
}
