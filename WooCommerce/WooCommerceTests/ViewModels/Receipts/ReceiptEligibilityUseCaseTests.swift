import XCTest
import Yosemite
@testable import WooCommerce

final class ReceiptEligibilityUseCaseTests: XCTestCase {
    func test_when_WooCommerce_version_is_below_minimum_then_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce",
                                              version: "8.5",
                                              active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }
        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForBackendReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_when_WooCommerce_version_is_equal_or_above_minimum_then_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce",
                                              version: "8.7.0",
                                              active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }
        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForBackendReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForFailedPaymentEmailReceipts_when_plugins_are_inactive_then_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let wooCommercePlugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.6.0", active: false)
        let wooPaymentsPlugin = SystemPlugin.fake().copy(name: CardPresentPaymentsPlugin.wcPay.pluginName, version: "8.9.0", active: false)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                if systemPluginName == "WooCommerce" {
                    onCompletion(wooCommercePlugin)
                } else if systemPluginName == CardPresentPaymentsPlugin.wcPay.pluginName {
                    onCompletion(wooPaymentsPlugin)
                }
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: CardPresentPaymentsPlugin.wcPay.gatewayID, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForFailedPaymentEmailReceipts_when_plugins_are_supported_then_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let wooCommercePlugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.5.0", active: true)
        let wooPaymentsPlugin = SystemPlugin.fake().copy(name: CardPresentPaymentsPlugin.wcPay.pluginName, version: "8.6.0", active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                if systemPluginName == "WooCommerce" {
                    onCompletion(wooCommercePlugin)
                } else if systemPluginName == CardPresentPaymentsPlugin.wcPay.pluginName {
                    onCompletion(wooPaymentsPlugin)
                }
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: CardPresentPaymentsPlugin.wcPay.gatewayID, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForFailedPaymentEmailReceipts_when_woopayments_version_is_incorrect_then_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let wooCommercePlugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.5.0", active: true)
        let wooPaymentsPlugin = SystemPlugin.fake().copy(name: CardPresentPaymentsPlugin.wcPay.pluginName, version: "5.0.0-dev", active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                if systemPluginName == "WooCommerce" {
                    onCompletion(wooCommercePlugin)
                } else if systemPluginName == CardPresentPaymentsPlugin.wcPay.pluginName {
                    onCompletion(wooPaymentsPlugin)
                }
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: CardPresentPaymentsPlugin.wcPay.gatewayID, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForFailedPaymentEmailReceipts_when_stripe_gateway_then_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let wooCommercePlugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.5.0", active: true)
        let stripePaymentsPlugin = SystemPlugin.fake().copy(name: CardPresentPaymentsPlugin.stripe.pluginName, version: "9.1.0", active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                if systemPluginName == "WooCommerce" {
                    onCompletion(wooCommercePlugin)
                } else if systemPluginName == CardPresentPaymentsPlugin.stripe.pluginName {
                    onCompletion(stripePaymentsPlugin)
                }
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: "woocommerce-stripe", onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForFailedPaymentEmailReceipts_when_stripe_gateway_is_outdated_then_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let wooCommercePlugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.5.0", active: true)
        let stripePaymentsPlugin = SystemPlugin.fake().copy(name: CardPresentPaymentsPlugin.stripe.pluginName, version: "9.0.0", active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                if systemPluginName == "WooCommerce" {
                    onCompletion(wooCommercePlugin)
                } else if systemPluginName == CardPresentPaymentsPlugin.stripe.pluginName {
                    onCompletion(stripePaymentsPlugin)
                }
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: "woocommerce-stripe", onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForReceipt_with_completed_status_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.5.0", active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.completed) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForReceipt_with_processing_status_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.5.0", active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.processing) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForReceipt_with_refunded_status_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.5.0", active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.refunded) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForReceipt_with_failed_status_and_no_gateway_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())

        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            switch action {
            case let .selectedPaymentGatewayAccount(onCompletion):
                onCompletion(nil)
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.failed) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForReceipt_with_failed_status_and_gateway_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())

        let gateway = createPaymentGatewayAccount()
        let wcPlugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.5.0", active: true)
        let wcPayPlugin = SystemPlugin.fake().copy(name: CardPresentPaymentsPlugin.wcPay.pluginName, version: "9.1.0", active: true)

        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            switch action {
            case let .selectedPaymentGatewayAccount(onCompletion):
                onCompletion(gateway)
            default:
                XCTFail("Unexpected action")
            }
        }

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, pluginName, onCompletion):
                if pluginName == "WooCommerce" {
                    onCompletion(wcPlugin)
                } else if pluginName == CardPresentPaymentsPlugin.wcPay.pluginName {
                    onCompletion(wcPayPlugin)
                }
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.failed) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForReceipt_with_cancelled_status_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.cancelled) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertFalse(isEligible)
    }
}

private extension ReceiptEligibilityUseCaseTests {
    func createPaymentGatewayAccount() -> PaymentGatewayAccount {
        .fake()
        .copy(
            siteID: 123,
            gatewayID: "woocommerce-payments",
            status: "complete",
            hasPendingRequirements: false,
            hasOverdueRequirements: false,
            isCardPresentEligible: true,
            isLive: true,
            isInTestMode: false
        )
    }
}
