import XCTest
import protocol Storage.StorageManagerType
import protocol Storage.StorageType
import Yosemite
import YosemiteTestHelpers
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
        insertPlugin("woocommerce-subscriptions/woocommerce-subscriptions.php", active: true)

        let checker = WooSubscriptionProductsEligibilityChecker(siteID: sampleSiteID,
                                                                storage: storageManager)

        // When
        let isEligible = checker.isSiteEligible()

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isSiteEligible_is_false_when_woo_subscriptions_is_installed_but_not_active() throws {
        // Given
        insertPlugin("woocommerce-subscriptions/woocommerce-subscriptions.php", active: false)

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

    func test_isSiteEligible_is_true_for_plugin_path_woocommerce_subscriptions() throws {
        // Given
        insertPlugin("woocommerce-subscriptions/woocommerce-subscriptions.php", active: true)

        let checker = WooSubscriptionProductsEligibilityChecker(siteID: sampleSiteID,
                                                                storage: storageManager)

        // When
        let isEligible = checker.isSiteEligible()

        // Then
        XCTAssertTrue(isEligible)
    }
}

private extension WooSubscriptionProductsEligibilityCheckerTests {
    func insertPlugin(_ pluginPath: String, active: Bool) {
        let systemPlugin = SystemPlugin.fake().copy(siteID: sampleSiteID, plugin: pluginPath, active: active)
        insert(systemPlugin)
    }

    func insert(_ readOnlyPlugin: SystemPlugin) {
        let plugin = storage.insertNewObject(ofType: StorageSystemPlugin.self)
        plugin.update(with: readOnlyPlugin)
        storage.saveIfNeeded()
    }
}
