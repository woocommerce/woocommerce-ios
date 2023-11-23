import XCTest
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
import Yosemite
@testable import WooCommerce

final class WooSubscriptionProductsEligibilityCheckerTests: XCTestCase {
    private let sampleSiteID: Int64 = 123

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

    // MARK: isSiteEligible

    func test_isSiteEligible_is_true_when_woo_subscriptions_is_installed_and_active() throws {
        // Given
        let activePlugin = SystemPlugin.fake().copy(siteID: sampleSiteID,
                                                    name: "Woo Subscriptions",
                                                    active: true)
        insert(activePlugin)

        let checker = WooSubscriptionProductsEligibilityChecker(siteID: sampleSiteID,
                                                                storage: storageManager)

        // When
        let isEligible = checker.isSiteEligible()

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isSiteEligible_is_false_when_woo_subscriptions_is_installed_but_not_active() throws {
        // Given
        let activePlugin = SystemPlugin.fake().copy(siteID: sampleSiteID,
                                                    name: "Woo Subscriptions",
                                                    active: false)
        insert(activePlugin)

        let checker = WooSubscriptionProductsEligibilityChecker(siteID: sampleSiteID,
                                                                storage: storageManager)

        // When
        let isEligible = checker.isSiteEligible()

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isSiteEligible_is_false_when_woo_subscriptions_is_not_installed() throws {
        // Given
        let checker = WooSubscriptionProductsEligibilityChecker(siteID: sampleSiteID,
                                                                storage: storageManager)

        // When
        let isEligible = checker.isSiteEligible()

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isSiteEligible_is_true_for_plugin_name_woocommerce_subscriptions() throws {
        // Given
        let activePlugin = SystemPlugin.fake().copy(siteID: sampleSiteID,
                                                    name: "WooCommerce Subscriptions",
                                                    active: true)
        insert(activePlugin)

        let checker = WooSubscriptionProductsEligibilityChecker(siteID: sampleSiteID,
                                                                storage: storageManager)

        // When
        let isEligible = checker.isSiteEligible()

        // Then
        XCTAssertTrue(isEligible)
    }

}

private extension WooSubscriptionProductsEligibilityCheckerTests {
    func insert(_ readOnlyPlugin: SystemPlugin) {
        let plugin = storage.insertNewObject(ofType: StorageSystemPlugin.self)
        plugin.update(with: readOnlyPlugin)
        storage.saveIfNeeded()
    }
}
