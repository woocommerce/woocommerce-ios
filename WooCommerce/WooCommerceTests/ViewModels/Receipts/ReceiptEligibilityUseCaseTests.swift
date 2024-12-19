import XCTest
import Yosemite
@testable import WooCommerce

final class ReceiptEligibilityUseCaseTests: XCTestCase {

    func test_isEligibleForBackendReceipts_when_feature_flag_is_disabled_then_returns_false() {
        // Given
        let featureFlag = MockFeatureFlagService(isBackendReceiptsEnabled: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForBackendReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForBackendReceipts_when_WooCommerce_version_is_incorrect_dev_version_then_returns_false() {
        // Given
        let featureFlag = MockFeatureFlagService(isBackendReceiptsEnabled: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce",
                                              version: "8.6.0-dev-wrong-version",
                                              active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForBackendReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForBackendReceipts_when_WooCommerce_version_is_correct_dev_version_then_returns_true() {
        // Given
        let featureFlag = MockFeatureFlagService(isBackendReceiptsEnabled: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce",
                                              version: "8.6.0-dev",
                                              active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForBackendReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForBackendReceipts_when_WooCommerce_version_is_below_minimum_then_returns_false() {
        // Given
        let featureFlag = MockFeatureFlagService(isBackendReceiptsEnabled: true)
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
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForBackendReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForPOSReceipts_when_WooCommerce_version_is_correct_version_then_returns_true() {
        // Given
        let featureFlag = MockFeatureFlagService(receiptsForPOS: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce",
                                              version: "9.5",
                                              active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForPointOfSaleReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForPOSReceipts_when_WooCommerce_version_is_incorrect_version_then_returns_false() {
        // Given
        let featureFlag = MockFeatureFlagService(receiptsForPOS: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let plugin = SystemPlugin.fake().copy(name: "WooCommerce",
                                              version: "9.4",
                                              active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action")
            }
        }
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForPointOfSaleReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForBackendReceipts_when_WooCommerce_version_is_equal_or_above_minimum_then_returns_true() {
        // Given
        let featureFlag = MockFeatureFlagService(isBackendReceiptsEnabled: true)
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
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForBackendReceipts(onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    // MARK: - Send Receipt After Payment

    func test_isEligibleForFailedPaymentEmailReceipts_when_feature_flag_is_disabled_then_returns_false() {
        // Given
        let featureFlag = MockFeatureFlagService(isSendReceiptAfterPaymentEnabled: false)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: GatewayID.wcPayments, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForFailedPaymentEmailReceipts_when_plugins_are_inactive_then_returns_false() {
        // Given
        let featureFlag = MockFeatureFlagService(isSendReceiptAfterPaymentEnabled: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let wooCommercePlugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.6.0", active: false)
        let wooPaymentsPlugin = SystemPlugin.fake().copy(name: "WooPayments", version: "8.9.0", active: false)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                if systemPluginName == "WooCommerce" {
                    onCompletion(wooCommercePlugin)
                } else if systemPluginName == "WooPayments" {
                    onCompletion(wooPaymentsPlugin)
                }
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: GatewayID.wcPayments, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForFailedPaymentEmailReceipts_when_plugins_are_supported_then_returns_true() {
        // Given
        let featureFlag = MockFeatureFlagService(isSendReceiptAfterPaymentEnabled: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let wooCommercePlugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.5.0", active: true)
        let wooPaymentsPlugin = SystemPlugin.fake().copy(name: "WooPayments", version: "8.6.0", active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                if systemPluginName == "WooCommerce" {
                    onCompletion(wooCommercePlugin)
                } else if systemPluginName == "WooPayments" {
                    onCompletion(wooPaymentsPlugin)
                }
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: GatewayID.wcPayments, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForFailedPaymentEmailReceipts_when_plugins_are_supported_dev_then_returns_true() {
        // Given
        let featureFlag = MockFeatureFlagService(isSendReceiptAfterPaymentEnabled: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let wooCommercePlugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.6.0-dev-1181231238", active: true)
        let wooPaymentsPlugin = SystemPlugin.fake().copy(name: "WooPayments", version: "8.6.0-test-1", active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                if systemPluginName == "WooCommerce" {
                    onCompletion(wooCommercePlugin)
                } else if systemPluginName == "WooPayments" {
                    onCompletion(wooPaymentsPlugin)
                }
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: GatewayID.wcPayments, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_isEligibleForFailedPaymentEmailReceipts_when_woopayments_version_is_incorrect_then_returns_false() {
        // Given
        let featureFlag = MockFeatureFlagService(isSendReceiptAfterPaymentEnabled: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let wooCommercePlugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.5.0", active: true)
        let wooPaymentsPlugin = SystemPlugin.fake().copy(name: "WooPayments", version: "5.0.0-dev", active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                if systemPluginName == "WooCommerce" {
                    onCompletion(wooCommercePlugin)
                } else if systemPluginName == "WooPayments" {
                    onCompletion(wooPaymentsPlugin)
                }
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: GatewayID.wcPayments, onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }

    func test_isEligibleForFailedPaymentEmailReceipts_when_plugins_are_supported_but_stripe_gateway_then_returns_false() {
        // Given
        let featureFlag = MockFeatureFlagService(isSendReceiptAfterPaymentEnabled: true)
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let wooCommercePlugin = SystemPlugin.fake().copy(name: "WooCommerce", version: "9.5.0", active: true)
        let wooPaymentsPlugin = SystemPlugin.fake().copy(name: "WooPayments", version: "8.6.0", active: true)

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, systemPluginName, onCompletion):
                if systemPluginName == "WooCommerce" {
                    onCompletion(wooCommercePlugin)
                } else if systemPluginName == "WooPayments" {
                    onCompletion(wooPaymentsPlugin)
                }
            default:
                XCTFail("Unexpected action")
            }
        }

        let sut = ReceiptEligibilityUseCase(stores: stores, featureFlagService: featureFlag)

        // When
        let isEligible: Bool = waitFor { promise in
            sut.isEligibleForFailedPaymentEmailReceipts(paymentGatewayID: "woocommerce-stripe", onCompletion: { result in
                promise(result)
            })
        }

        // Then
        XCTAssertFalse(isEligible)
    }
}

private extension ReceiptEligibilityUseCaseTests {
    enum GatewayID {
        static let wcPayments: String = "woocommerce-payments"
    }
}
