import XCTest
import Yosemite
import protocol Storage.StorageManagerType
@testable import WooCommerce

final class StorePickerViewModelTests: XCTestCase {
    private var storageManager: MockStorageManager!
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        super.tearDown()
        storageManager = nil
        stores = nil
    }

    func test_multipleStoresAvailable_is_correct_for_single_store() {
        // Given
        let testSite = Site.fake()
        storageManager.insertSampleSite(readOnlySite: testSite)
        let viewModel = StorePickerViewModel(configuration: .standard, stores: stores, storageManager: storageManager)

        // When
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, _, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        viewModel.refreshSites(currentlySelectedSiteID: nil)

        // Then
        XCTAssertFalse(viewModel.multipleStoresAvailable)
    }

    func test_multipleStoresAvailable_is_correct_for_multiple_stores() {
        // Given
        let testSite1 = Site.fake().copy(siteID: 123)
        let testSite2 = Site.fake().copy(siteID: 243)
        storageManager.insertSampleSite(readOnlySite: testSite1)
        storageManager.insertSampleSite(readOnlySite: testSite2)
        let viewModel = StorePickerViewModel(configuration: .standard, storageManager: storageManager)

        // When
        stores.whenReceivingAction(ofType: AccountAction.self) { action in
            switch action {
            case let .synchronizeSites(_, _, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }
        viewModel.refreshSites(currentlySelectedSiteID: nil)

        // Then
        XCTAssertTrue(viewModel.multipleStoresAvailable)
    }
}
