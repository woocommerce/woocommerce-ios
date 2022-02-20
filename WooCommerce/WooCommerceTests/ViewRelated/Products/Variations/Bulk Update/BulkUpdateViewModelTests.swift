import XCTest
import Yosemite
import Combine

@testable import WooCommerce

/// Tests for `BulkUpdateViewModel`.
///
final class BulkUpdateViewModelTests: XCTestCase {

    private var storesManager: MockStoresManager!
    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())
    }

    override func tearDown() {
        storageManager = nil
        storesManager = nil
        super.tearDown()
    }

    func test_all_products_are_synchronized_on_the_viewload_event() throws {
        // Given
        let expectedSiteID: Int64 = 42
        let expectedProductID: Int64 = 19
        let expectedPageSize = 101
        let expectedPageNumber = 1
        let viewModel = BulkUpdateViewModel(siteID: expectedSiteID, productID: expectedProductID, storageManager: storageManager, storesManager: storesManager)

        // When
        viewModel.activate()

        // Then
        let action = try XCTUnwrap(storesManager.receivedActions.first as? ProductVariationAction)

        guard case let .synchronizeProductVariations(siteID: siteID, productID: productID, pageNumber: pageNumber, pageSize: pageSize, _) = action else {
            XCTFail("Expected \(action) to be \(ProductVariationAction.self).synchronizeProductVariations.")
            return
        }

        XCTAssertEqual(siteID, expectedSiteID)
        XCTAssertEqual(productID, expectedProductID)
        XCTAssertEqual(pageNumber, expectedPageNumber)
        XCTAssertEqual(pageSize, expectedPageSize)
    }

    func test_initial_sync_state() throws {
        // Given
        let viewModel = BulkUpdateViewModel(siteID: 0, productID: 0, storageManager: storageManager, storesManager: storesManager)

        // Then
        XCTAssertEqual(viewModel.syncState, .notStarted)
    }

    func test_sync_state_updates_to_loading_when_product_variations_syncing_starts() {
        // Given
        let viewModel = BulkUpdateViewModel(siteID: 0, productID: 0, storageManager: storageManager, storesManager: storesManager)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { _ in
            // do nothing to stay in "syncing" state
        }

        // When
        viewModel.activate()

        // Then
        XCTAssertEqual(viewModel.syncState, .syncing)
    }

    func test_sync_state_updates_to_syncerror_when_product_variations_syncing_fails() {
        // Given
        let viewModel = BulkUpdateViewModel(siteID: 0, productID: 0, storageManager: storageManager, storesManager: storesManager)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, onCompletion):
                onCompletion(NSError.init(domain: "sample error", code: 0, userInfo: nil))
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.activate()

        // Then
        XCTAssertEqual(viewModel.syncState, .syncingError)
    }

    func test_sync_state_updates_to_syncResults_when_product_variations_syncing_is_successful() {
        // Given
        let viewModel = BulkUpdateViewModel(siteID: 0, productID: 0, storageManager: storageManager, storesManager: storesManager)
        storesManager.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            switch action {
            case let .synchronizeProductVariations(_, _, _, _, onCompletion):
                onCompletion(nil)
            default:
                XCTFail("Unsupported Action")
            }
        }

        // When
        viewModel.activate()

        // Then
        XCTAssertEqual(viewModel.syncState, .syncedResults)
    }
}
