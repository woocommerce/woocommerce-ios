import XCTest
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce

final class ProductPasswordEligibilityUseCaseTests: XCTestCase {

    private var sut: ProductPasswordEligibilityUseCase!
    private var storageManager: MockStorageManager!
    private var stores: MockStoresManager!

    private let pluginPath = "woocommerce/woocommerce.php"
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
        let result = sut.isEligibleForWooProductPasswordEndpoint()

        // Then
        XCTAssertFalse(result)
    }

    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_is_not_active_return_false() {
        // Given
        insertWooCommercePlugin(version: "9.0", active: false)

        // When
        let result = sut.isEligibleForWooProductPasswordEndpoint()

        // Then
        XCTAssertFalse(result)
    }

    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_version_is_below_minimum_return_false() {
        // Given
        insertWooCommercePlugin(version: "7.0", active: true)

        // When
        let result = sut.isEligibleForWooProductPasswordEndpoint()

        // Then
        XCTAssertFalse(result)
    }

    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_version_is_equal_to_minimum_return_true() {
        // Given
        insertWooCommercePlugin(version: "8.1.0", active: true)

        // When
        let result = sut.isEligibleForWooProductPasswordEndpoint()

        // Then
        XCTAssertTrue(result)
    }

    func test_isEligibleForNewPasswordEndpoint_when_WooCommerce_version_is_above_to_minimum_return_true() {
        // Given
        insertWooCommercePlugin(version: "9.1.0", active: true)

        // When
        let result = sut.isEligibleForWooProductPasswordEndpoint()

        // Then
        XCTAssertTrue(result)
    }

    func test_editing_product_and_password_when_WooCommerce_version_is_below_8_1_returns_false() {
        // Given
        insertWooCommercePlugin(version: "8.0.0", active: true)

        let sut = ProductPasswordEligibilityUseCase(stores: stores, storageManager: storageManager)

        // When
        let isEligible: Bool = sut.isEligibleForWooProductPasswordEndpoint()

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForWooProductPasswordEndpoint_when_WooCommerce_version_is_equal_to_8_1_returns_true() {
        // Given
        insertWooCommercePlugin(version: "8.1.0", active: true)

        let sut = ProductPasswordEligibilityUseCase(stores: stores, storageManager: storageManager)

        // When
        let isEligible: Bool = sut.isEligibleForWooProductPasswordEndpoint()

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_editing_product_and_password_when_WooCommerce_version_is_above_8_1_returns_true() {
        // Given
        insertWooCommercePlugin(version: "8.2.0", active: true)

        let sut = ProductPasswordEligibilityUseCase(stores: stores, storageManager: storageManager)

        // When
        let isEligible: Bool = sut.isEligibleForWooProductPasswordEndpoint()

        // Then
        XCTAssertTrue(isEligible)
    }
}

private extension ProductPasswordEligibilityUseCaseTests {
    func insertWooCommercePlugin(version: String, active: Bool) {
        let plugin = SystemPlugin.fake().copy(siteID: siteID, plugin: pluginPath, version: version, active: active)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: plugin)
    }
}
