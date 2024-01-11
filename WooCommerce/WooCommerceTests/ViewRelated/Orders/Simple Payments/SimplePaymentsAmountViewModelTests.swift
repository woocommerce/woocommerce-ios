import Foundation
import XCTest
import Combine
import WooFoundation
@testable import WooCommerce
@testable import Yosemite

final class SimplePaymentsAmountViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 123

    private let usStoreSettings = CurrencySettings() // Default is US settings

    private var subscriptions = Set<AnyCancellable>()

    func test_view_model_disables_next_button_when_there_is_no_amount() {
        // Given
        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID)

        // When
        viewModel.formattableAmountTextFieldViewModel.amount = ""

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_disables_next_button_when_amount_only_has_currency_symbol() {
        // Given
        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID, storeCurrencySettings: usStoreSettings)

        // When
        viewModel.formattableAmountTextFieldViewModel.amount = "$"

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_disables_next_button_when_amount_is_not_greater_than_zero() {
        // Given
        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID, storeCurrencySettings: usStoreSettings)

        // When
        viewModel.formattableAmountTextFieldViewModel.amount = "$0"

        // Then
        XCTAssertTrue(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_enables_next_button_when_amount_has_more_than_one_character() {
        // Given
        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID, storeCurrencySettings: usStoreSettings)

        // When
        viewModel.formattableAmountTextFieldViewModel.amount = "$2"

        // Then
        XCTAssertFalse(viewModel.shouldDisableDoneButton)
    }

    func test_view_model_enables_loading_state_while_performing_network_operations() {
        // Given
        let testingStore = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID, stores: testingStore)
        viewModel.formattableAmountTextFieldViewModel.amount = "$12.30"
        XCTAssertFalse(viewModel.loading)

        // When
        let isLoading: Bool = waitFor { promise in
            testingStore.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createSimplePaymentsOrder:
                    promise(viewModel.loading)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            viewModel.createSimplePaymentsOrder()
        }

        // Then
        XCTAssertTrue(isLoading)
    }

    func test_order_is_created_with_taxes() {
        // Given
        let testingStore = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID, stores: testingStore)
        viewModel.formattableAmountTextFieldViewModel.amount = "$12.30"

        // When
        let taxable: Bool = waitFor { promise in
            testingStore.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createSimplePaymentsOrder(_, _, _, taxable, _):
                    promise(taxable)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            viewModel.createSimplePaymentsOrder()
        }

        // Then
        XCTAssertTrue(taxable)
    }

    func test_order_is_created_with_pending_status() {
        // Given
        let testingStore = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID, stores: testingStore)
        viewModel.formattableAmountTextFieldViewModel.amount = "$12.30"

        // When
        let status: OrderStatusEnum = waitFor { promise in
            testingStore.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createSimplePaymentsOrder(_, status, _, _, _):
                    promise(status)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            viewModel.createSimplePaymentsOrder()
        }

        // Then
        XCTAssertEqual(status, .pending)
    }

    func test_order_is_created_with_draft_status() {
        // Given
        let testingStore = MockStoresManager(sessionManager: .testingInstance)
        testingStore.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                let plugin = SystemPlugin.fake().copy(version: "6.3.0")
                onCompletion(plugin)
            default:
                XCTFail("Unexpected action received: \(action)")
            }
        }

        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID, stores: testingStore)
        viewModel.formattableAmountTextFieldViewModel.amount = "$12.30"

        // When
        let status: OrderStatusEnum = waitFor { promise in
            testingStore.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createSimplePaymentsOrder(_, status, _, _, _):
                    promise(status)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            viewModel.createSimplePaymentsOrder()
        }

        // Then
        XCTAssertEqual(status, .autoDraft)
    }

    func test_summaryViewModel_is_created_after_an_order_is_created() {
        // Given
        let testingStore = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID, stores: testingStore)

        // When
        waitForExpectation { exp in
            testingStore.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createSimplePaymentsOrder(_, _, _, _, onCompletion):
                    onCompletion(.success(.fake()))
                    exp.fulfill()
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            viewModel.createSimplePaymentsOrder()
        }

        // Then
        XCTAssertNotNil(viewModel.summaryViewModel)
        XCTAssertTrue(viewModel.navigateToSummary)
    }

    func test_summaryViewModel_is_nilled_after_navigation_is_set_to_false() {
        // Given
        let testingStore = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID, stores: testingStore)
        waitForExpectation { exp in
            testingStore.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createSimplePaymentsOrder(_, _, _, _, onCompletion):
                    onCompletion(.success(.fake()))
                    exp.fulfill()
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            viewModel.createSimplePaymentsOrder()
        }

        // When
        viewModel.navigateToSummary = false

        // Then
        XCTAssertNil(viewModel.summaryViewModel)
    }

    func test_view_model_attempts_error_notice_presentation_when_failing_to_create_order() {
        // Given
        let testingStore = MockStoresManager(sessionManager: .testingInstance)
        let noticeSubject = PassthroughSubject<SimplePaymentsNotice, Never>()
        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID, stores: testingStore, presentNoticeSubject: noticeSubject)
        testingStore.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .createSimplePaymentsOrder(_, _, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "Error", code: 0)))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let receivedError: Bool = waitFor { promise in
            noticeSubject.sink { intent in
                switch intent {
                case .error:
                    promise(true)
                case .completed, .created:
                    promise(false)
                }
            }
            .store(in: &self.subscriptions)
            viewModel.createSimplePaymentsOrder()
        }

        // Then
        XCTAssertTrue(receivedError)
    }

    func test_failure_is_tracked_when_failing_to_create_order() {
        // Given
        let testingStore = MockStoresManager(sessionManager: .testingInstance)
        testingStore.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .createSimplePaymentsOrder(_, _, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "Error", code: 0)))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        let analytics = MockAnalyticsProvider()
        let currencySettings = CurrencySettings()
        currencySettings.currencyCode = .JPY
        let siteAddress = SiteAddress(siteSettings: [.fake().copy(settingID: "woocommerce_default_country", value: "US:PA")])
        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID,
                                                      stores: testingStore,
                                                      storeCurrencySettings: currencySettings,
                                                      countryCode: .JP,
                                                      analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.createSimplePaymentsOrder()

        // Then
        assertEqual(analytics.receivedEvents, [WooAnalyticsStat.paymentsFlowFailed.rawValue])
        assertEqual(analytics.receivedProperties.first?["source"] as? String, "amount")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["country"] as? String, "JP")
        assertEqual(analytics.receivedProperties.first?["currency"] as? String, "JPY")
    }

    func test_view_model_disable_cancel_button_while_creating_payment_order() {
        // Given
        let testingStore = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = SimplePaymentsAmountViewModel(siteID: sampleSiteID, stores: testingStore)
        viewModel.formattableAmountTextFieldViewModel.amount = "$10.30"
        XCTAssertFalse(viewModel.loading)

        // Before creating simple payment order
        XCTAssertFalse(viewModel.disableViewActions)

        // When
        let _: Bool = waitFor { promise in
            testingStore.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createSimplePaymentsOrder:
                    promise(viewModel.loading)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            viewModel.createSimplePaymentsOrder()
        }

        // Then
        XCTAssertTrue(viewModel.disableViewActions)
    }

}
