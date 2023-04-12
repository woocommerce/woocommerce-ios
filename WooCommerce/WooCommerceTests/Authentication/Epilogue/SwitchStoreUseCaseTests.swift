import XCTest
import struct Yosemite.Site
@testable import WooCommerce

/// Test cases for `SwitchStoreUseCase`.
///
final class SwitchStoreUseCaseTests: XCTestCase {
    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    // MARK: getAvailableStores

    func test_it_returns_only_woocommerce_sites() {
        // Given
        let wooCommerceSite = Site.fake().copy(isWooCommerceActive: true)
        let notAWooCommerceSite = Site.fake().copy(isWooCommerceActive: false)
        storageManager.insertSampleSite(readOnlySite: wooCommerceSite)
        storageManager.insertSampleSite(readOnlySite: notAWooCommerceSite)

        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = SwitchStoreUseCase(stores: stores, storageManager: storageManager)

        // Then
        XCTAssertEqual(sut.getAvailableStores(), [wooCommerceSite])
    }
}
