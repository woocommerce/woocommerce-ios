import XCTest
import Yosemite
@testable import WooCommerce

@MainActor
final class ReceiptEligibilityUseCaseTests: XCTestCase {
    func test_when_WooCommerce_version_is_below_minimum_then_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let mockPluginsService = MockPluginsService()
        let plugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                              version: "8.5",
                                              active: true)
        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: plugin)

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

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
        let mockPluginsService = MockPluginsService()
        let plugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php",
                                              version: "8.7.0",
                                              active: true)
        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: plugin)

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

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
        let mockPluginsService = MockPluginsService()

        let wooCommercePlugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "9.6.0", active: false)
        let wooPaymentsPlugin = SystemPlugin.fake().copy(plugin: "woocommerce-payments/woocommerce-payments.php", version: "8.9.0", active: false)

        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: wooCommercePlugin)
        mockPluginsService.setMockPlugin(.wooPayments, systemPlugin: wooPaymentsPlugin)

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

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
        let mockPluginsService = MockPluginsService()

        let wooCommercePlugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "9.5.0", active: true)
        let wooPaymentsPlugin = SystemPlugin.fake().copy(plugin: "woocommerce-payments/woocommerce-payments.php", version: "8.6.0", active: true)

        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: wooCommercePlugin)
        mockPluginsService.setMockPlugin(.wooPayments, systemPlugin: wooPaymentsPlugin)

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

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
        let mockPluginsService = MockPluginsService()

        let wooCommercePlugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "9.5.0", active: true)
        let wooPaymentsPlugin = SystemPlugin.fake().copy(plugin: "woocommerce-payments/woocommerce-payments.php", version: "5.0.0-dev", active: true)

        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: wooCommercePlugin)
        mockPluginsService.setMockPlugin(.wooPayments, systemPlugin: wooPaymentsPlugin)

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

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
        let mockPluginsService = MockPluginsService()

        let wooCommercePlugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "9.5.0", active: true)
        let stripePaymentsPlugin = SystemPlugin.fake().copy(plugin: "woocommerce-gateway-stripe/woocommerce-gateway-stripe.php", version: "9.1.0", active: true)

        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: wooCommercePlugin)
        mockPluginsService.setMockPlugin(.stripe, systemPlugin: stripePaymentsPlugin)

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

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
        let mockPluginsService = MockPluginsService()

        let wooCommercePlugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "9.5.0", active: true)
        let stripePaymentsPlugin = SystemPlugin.fake().copy(plugin: "woocommerce-gateway-stripe/woocommerce-gateway-stripe.php", version: "9.0.0", active: true)

        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: wooCommercePlugin)
        mockPluginsService.setMockPlugin(.stripe, systemPlugin: stripePaymentsPlugin)

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

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
        let mockPluginsService = MockPluginsService()
        let plugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "9.5.0", active: true)
        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: plugin)

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.completed, datePaid: Date()) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForReceipt_with_minimum_wc_version_and_processing_status_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let mockPluginsService = MockPluginsService()
        let plugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "9.5.0", active: true)
        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: plugin)

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.processing, datePaid: Date()) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForReceipt_with_minimum_wc_version_and_refunded_status_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let mockPluginsService = MockPluginsService()
        let plugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "9.5.0", active: true)
        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: plugin)

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.refunded, datePaid: Date()) { result in
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
            sut.isEligibleForReceipt(.failed, datePaid: nil) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForReceipt_with_failed_status_and_gateway_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let mockPluginsService = MockPluginsService()

        let gateway = createPaymentGatewayAccount()
        let wcPlugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "9.5.0", active: true)
        let wcPayPlugin = SystemPlugin.fake().copy(plugin: "woocommerce-payments/woocommerce-payments.php", version: "9.1.0", active: true)

        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: wcPlugin)
        mockPluginsService.setMockPlugin(.wooPayments, systemPlugin: wcPayPlugin)

        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            switch action {
            case let .selectedPaymentGatewayAccount(onCompletion):
                onCompletion(gateway)
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.failed, datePaid: nil) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForReceipt_with_paid_custom_status_returns_true() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let mockPluginsService = MockPluginsService()
        let plugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "9.5.0", active: true)
        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: plugin)

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.custom("shipped"), datePaid: Date()) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForReceipt_with_unpaid_custom_status_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let mockPluginsService = MockPluginsService()
        let plugin = SystemPlugin.fake().copy(plugin: "woocommerce/woocommerce.php", version: "9.5.0", active: true)
        mockPluginsService.setMockPlugin(.wooCommerce, systemPlugin: plugin)

        let sut = ReceiptEligibilityUseCase(stores: stores, pluginsService: mockPluginsService)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.custom("awaiting-approval"), datePaid: nil) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForReceipt_with_cancelled_status_returns_false() {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = ReceiptEligibilityUseCase(stores: stores)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForReceipt(.cancelled, datePaid: nil) { result in
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
