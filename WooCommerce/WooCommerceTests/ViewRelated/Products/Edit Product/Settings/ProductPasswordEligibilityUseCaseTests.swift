import XCTest
import Yosemite
@testable import WooCommerce

final class ProductPasswordEligibilityUseCaseTests: XCTestCase {

    private var sut: ProductPasswordEligibilityUseCase!
    private var storageManager: MockStorageManager!
    private var stores: MockStoresManager!

    private let pluginName = "WooCommerce"
    private let siteID: Int64 = 1

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.sessionManager.setStoreId(siteID)
        sut = ProductPasswordEligibilityUseCase(stores: stores, storageManager: storageManager)
    }

    override func tearDown() {
        super.tearDown()
        storageManager = nil
        stores = nil
        sut = nil
    }

    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_is_not_installed_return_false() {
        // When
        let result = sut.isEligibleForNewPasswordEndpoint()

        // Then
        XCTAssertFalse(result)
    }

    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_is_not_active_return_false() {
        // Given
        let inactivePlugin = SystemPlugin.fake().copy(siteID: siteID, name: pluginName, version: "9.0", active: false)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: inactivePlugin)

        // When
        let result = sut.isEligibleForNewPasswordEndpoint()

        // Then
        XCTAssertFalse(result)
    }

    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_version_is_below_minimum_return_false() {
        // Given
        let oldVersionPlugin = SystemPlugin.fake().copy(siteID: siteID, name: pluginName, version: "7.0", active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: oldVersionPlugin)

        // When
        let result = sut.isEligibleForNewPasswordEndpoint()

        // Then
        XCTAssertFalse(result)
    }

    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_version_is_equal_to_minimum_return_true() {
        // Given
        let validPlugin = SystemPlugin.fake().copy(siteID: siteID, name: pluginName, version: "8.1.0", active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: validPlugin)

        // When
        let result = sut.isEligibleForNewPasswordEndpoint()

        // Then
        XCTAssertTrue(result)
    }

    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_version_is_above_to_minimum_return_true() {
        // Given
        let validPlugin = SystemPlugin.fake().copy(siteID: siteID, name: pluginName, version: "9.1.0", active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: validPlugin)

        // When
        let result = sut.isEligibleForNewPasswordEndpoint()

        // Then
        XCTAssertTrue(result)
    }
}
