import XCTest
import Yosemite
@testable import WooCommerce

final class CardPresentPluginsDataProviderTests: XCTestCase {
    private var sut: CardPresentPluginsDataProvider!
    private var storageManager: MockStorageManager!
    private var stores: MockStoresManager!
    private let configurationLoader = CardPresentConfigurationLoader(stores: ServiceLocator.stores)

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .testingInstance)


        sut = CardPresentPluginsDataProvider(storageManager: storageManager,
                                             stores: stores,
                                             configurationLoader: configurationLoader)
    }

    override func tearDown() {
        super.tearDown()

        sut = nil
    }

    func test_paymentPluginsInstalledAndActiveStatus_when_both_are_nil_returns_noneAreInstalledAndActive() {
        let status = sut.paymentPluginsInstalledAndActiveStatus(wcPay: nil, stripe: nil)
        XCTAssertEqual(status, .noneAreInstalledAndActive)
    }

    func test_paymentPluginsInstalledAndActiveStatus_when_neither_are_active_returns_noneAreInstalledAndActive() {
        // Given
        let wcPay = SystemPlugin.fake().copy(active: false)
        let stripe = SystemPlugin.fake().copy(active: false)

        // When
        let status = sut.paymentPluginsInstalledAndActiveStatus(wcPay: wcPay, stripe: stripe)

        // Then
        XCTAssertEqual(status, .noneAreInstalledAndActive)
    }

    func test_paymentPluginsInstalledAndActiveStatus_when_only_wcPay_is_active_returns_onlyWCPayIsInstalledAndActive() {
        // Given
        let wcPay = SystemPlugin.fake().copy(active: true)
        let stripe = SystemPlugin.fake().copy(active: false)

        // When
        let status = sut.paymentPluginsInstalledAndActiveStatus(wcPay: wcPay, stripe: stripe)

        // Then
        XCTAssertEqual(status, .onlyWCPayIsInstalledAndActive)
    }

    func test_paymentPluginsInstalledAndActiveStatus_when_only_stripe_is_active_returns_onlyStripeIsInstalledAndActive() {
        // Given
        let wcPay = SystemPlugin.fake().copy(active: false)
        let stripe = SystemPlugin.fake().copy(active: true)

        // When
        let status = sut.paymentPluginsInstalledAndActiveStatus(wcPay: wcPay, stripe: stripe)

        // Then
        XCTAssertEqual(status, .onlyStripeIsInstalledAndActive)
    }

    func test_paymentPluginsInstalledAndActiveStatus_when_both_are_active_returns_bothAreInstalledAndActive() {
        // Given
        let wcPay = SystemPlugin.fake().copy(active: true)
        let stripe = SystemPlugin.fake().copy(active: true)

        // When
        let status = sut.paymentPluginsInstalledAndActiveStatus(wcPay: wcPay, stripe: stripe)

        // Then
        XCTAssertEqual(status, .bothAreInstalledAndActive)
    }

    func test_getWCPayPlugin_when_it_is_stored_then_returns_it() {
        // Given
        let siteID: Int64 = 1
        stores.sessionManager.setStoreId(siteID)
        let fileNameWithoutExtension = "woocommerce-payments"
        let plugin = SystemPlugin.fake().copy(siteID: siteID, plugin: "folder/" + fileNameWithoutExtension + ".ext")
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: plugin)


        // When
        let retrievedPlugin = sut.getWCPayPlugin()

        XCTAssertEqual(retrievedPlugin, plugin)
    }

    func test_getStripePlugin_when_it_is_stored_then_returns_it() {
        // Given
        let siteID: Int64 = 1
        stores.sessionManager.setStoreId(siteID)
        let fileNameWithoutExtension = "woocommerce-gateway-stripe"
        let plugin = SystemPlugin.fake().copy(siteID: siteID, plugin: "folder/" + fileNameWithoutExtension + ".ext")
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: plugin)


        // When
        let retrievedPlugin = sut.getStripePlugin()

        XCTAssertEqual(retrievedPlugin, plugin)
    }
}
