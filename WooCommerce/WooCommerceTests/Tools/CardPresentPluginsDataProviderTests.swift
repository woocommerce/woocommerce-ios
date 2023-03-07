import XCTest
import Yosemite
@testable import WooCommerce

final class CardPresentPluginsDataProviderTests: XCTestCase {
    private var sut: CardPresentPluginsDataProvider!

    override func setUp() {
        super.setUp()

        let configuration = CardPresentConfigurationLoader(stores: ServiceLocator.stores).configuration
        sut = CardPresentPluginsDataProvider(configuration: configuration)
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
}
