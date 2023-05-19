import Foundation
import XCTest
import Combine
import Fakes

@testable import WooCommerce
@testable import Yosemite

private typealias Dependencies = PaymentMethodsViewModel.Dependencies

final class PaymentMethodsViewModelTests: XCTestCase {

    var subscriptions = Set<AnyCancellable>()

    func test_loading_is_enabled_while_marking_order_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(nil)
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let dependencies = Dependencies(stores: stores)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        let loadingStates: [Bool] = waitFor { promise in
            viewModel.$showLoadingIndicator
                .dropFirst() // Initial value
                .collect(2)  // Collect toggle
                .first()
                .sink { loadingStates in
                    promise(loadingStates)
                }
                .store(in: &self.subscriptions)
            viewModel.markOrderAsPaid(onSuccess: {})
        }

        // Then
        XCTAssertEqual(loadingStates, [true, false]) // Loading, then not loading.
    }

    func test_view_is_disabled_while_loading_is_enabled() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let dependencies = Dependencies(stores: stores)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        let loading: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .updateOrderStatus:
                    promise(viewModel.showLoadingIndicator)
                case .retrieveOrder:
                    break
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }

            viewModel.markOrderAsPaid(onSuccess: {})
        }

        // Then
        XCTAssertTrue(loading)
        XCTAssertTrue(viewModel.disableViewActions)
    }

    func test_view_model_updates_order_async_after_order_marked_as_paid() throws {
        // Given
        let storage = MockStorageManager()
        let order = Order.fake().copy(status: .pending)
        storage.insertSampleOrder(readOnlyOrder: order)
        storage.insertSamplePaymentGatewayAccount(readOnlyAccount: .fake())

        let stores = MockStoresManager(sessionManager: .testingInstance)

        let dependencies = Dependencies(stores: stores,
                                        storage: storage)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        let (siteID, orderID): (Int64, Int64) = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .updateOrderStatus(_, _, _, onCompletion):
                    onCompletion(nil)
                case let .retrieveOrder(siteID, orderID, _):
                    promise((siteID, orderID))
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }
            viewModel.markOrderAsPaid(onSuccess: {})
        }

        // Then
        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
    }

    func test_onSuccess_is_invoked_after_order_is_marked_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let dependencies = Dependencies(stores: stores)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(nil)
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let onSuccessInvoked: Bool = waitFor { promise in
            viewModel.markOrderAsPaid(onSuccess: {
                promise(true)
            })
        }

        // Then
        XCTAssertTrue(onSuccessInvoked)
    }

    func test_view_model_attempts_completed_notice_presentation_when_marking_an_order_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let noticeSubject = PassthroughSubject<SimplePaymentsNotice, Never>()
        let dependencies = Dependencies(presentNoticeSubject: noticeSubject, stores: stores)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(nil)
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let receivedCompleted: Bool = waitFor { promise in
            noticeSubject.sink { intent in
                switch intent {
                case .error, .created:
                    promise(false)
                case .completed:
                    promise(true)
                }
            }
            .store(in: &self.subscriptions)
            viewModel.markOrderAsPaid(onSuccess: {})
        }

        // Then
        XCTAssertTrue(receivedCompleted)
    }

    func test_view_model_attempts_error_notice_presentation_when_failing_to_mark_order_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let noticeSubject = PassthroughSubject<SimplePaymentsNotice, Never>()
        let dependencies = Dependencies(presentNoticeSubject: noticeSubject, stores: stores)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(NSError(domain: "Error", code: 0))
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
            viewModel.markOrderAsPaid(onSuccess: {})
        }

        // Then
        XCTAssertTrue(receivedError)
    }

    func test_completed_event_is_tracked_after_marking_order_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(nil)
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let analytics = MockAnalyticsProvider()
        let orderID: Int64 = 232
        let dependencies = Dependencies(stores: stores,
                                        analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = PaymentMethodsViewModel(orderID: orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        viewModel.markOrderAsPaid(onSuccess: {})

        // Then
        assertEqual(analytics.receivedEvents.first, WooAnalyticsStat.paymentsFlowCompleted.rawValue)
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "cash")
        assertEqual(analytics.receivedProperties.first?["amount"] as? String, "$12.00")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["order_id"] as? Int64, orderID)
    }

    func test_completed_event_is_tracked_after_collecting_payment_successfully() {
        // Given
        let storage = MockStorageManager()
        let insertOrder = Order.fake()
        storage.insertSampleOrder(readOnlyOrder: insertOrder)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .selectedPaymentGatewayAccount(onCompletion) = action {
                onCompletion(PaymentGatewayAccount.fake())
            }
        }

        let analytics = MockAnalyticsProvider()
        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .success(()))
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(
            cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
            stores: stores,
            storage: storage,
            analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = PaymentMethodsViewModel(orderID: insertOrder.orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        viewModel.collectPayment(on: UIViewController(), useCase: useCase, onSuccess: {}, onFailure: {})

        // Then
        assertEqual(analytics.receivedEvents.last, WooAnalyticsStat.paymentsFlowCompleted.rawValue)
        assertEqual(analytics.receivedProperties.last?["payment_method"] as? String, "card")
        assertEqual(analytics.receivedProperties.last?["amount"] as? String, "$12.00")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["order_id"] as? Int64, insertOrder.orderID)
    }

    func test_completed_event_is_tracked_after_sharing_a_link() {
        // Given
        let analytics = MockAnalyticsProvider()
        let orderID: Int64 = 232
        let dependencies = Dependencies(analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = PaymentMethodsViewModel(orderID: orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        viewModel.performLinkSharedTasks()

        // Then
        assertEqual(analytics.receivedEvents.first, WooAnalyticsStat.paymentsFlowCompleted.rawValue)
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "payment_link")
        assertEqual(analytics.receivedProperties.first?["amount"] as? String, "$12.00")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["order_id"] as? Int64, orderID)
    }

    func test_completed_event_is_tracked_after_scanning_to_pay() {
        // Given
        let analytics = MockAnalyticsProvider()
        let orderID: Int64 = 232
        let dependencies = Dependencies(analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = PaymentMethodsViewModel(orderID: orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        viewModel.performScanToPayFinishedTasks()

        // Then
        assertEqual(analytics.receivedEvents.first, WooAnalyticsStat.paymentsFlowCompleted.rawValue)
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "scan_to_pay")
        assertEqual(analytics.receivedProperties.first?["amount"] as? String, "$12.00")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["order_id"] as? Int64, orderID)
    }

    func test_failed_event_is_tracked_after_failing_to_mark_order_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(NSError(domain: "", code: 0, userInfo: nil))
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let analytics = MockAnalyticsProvider()
        let dependencies = Dependencies(stores: stores,
                                        analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        viewModel.markOrderAsPaid(onSuccess: {})

        // Then
        assertEqual(analytics.receivedEvents.first, WooAnalyticsStat.paymentsFlowFailed.rawValue)
        assertEqual(analytics.receivedProperties.first?["source"] as? String, "payment_method")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
    }

    func test_failed_event_is_tracked_after_failing_to_collect_payment() {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleOrder(readOnlyOrder: .fake())
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .selectedPaymentGatewayAccount(onCompletion) = action {
                onCompletion(PaymentGatewayAccount.fake())
            }
        }

        let analytics = MockAnalyticsProvider()
        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .failure(NSError(domain: "Error", code: 0, userInfo: nil)))
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(
            cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
            stores: stores,
            storage: storage,
            analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        viewModel.collectPayment(on: UIViewController(), useCase: useCase, onSuccess: {}, onFailure: {})

        // Then
        assertEqual(analytics.receivedEvents.last, WooAnalyticsStat.paymentsFlowFailed.rawValue)
        assertEqual(analytics.receivedProperties.last?["source"] as? String, "payment_method")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
    }

    func test_collect_event_is_tracked_when_paying_by_cash() {
        // Given
        let analytics = MockAnalyticsProvider()
        let orderID: Int64 = 232
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let dependencies = Dependencies(stores: stores,
                                        analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = PaymentMethodsViewModel(orderID: orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        viewModel.trackCollectByCash()

        // Then
        assertEqual(analytics.receivedEvents, [WooAnalyticsStat.paymentsFlowCollect.rawValue])
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "cash")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["order_id"] as? Int64, orderID)
    }

    func test_collect_event_is_tracked_when_sharing_payment_links() {
        // Given
        let analytics = MockAnalyticsProvider()
        let orderID: Int64 = 232
        let dependencies = Dependencies(analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = PaymentMethodsViewModel(orderID: orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        viewModel.trackCollectByPaymentLink()

        // Then
        assertEqual(analytics.receivedEvents, [WooAnalyticsStat.paymentsFlowCollect.rawValue])
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "payment_link")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["order_id"] as? Int64, orderID)
    }

    func test_collect_event_is_tracked_when_scanning_to_pay() {
        // Given
        let analytics = MockAnalyticsProvider()
        let orderID: Int64 = 232
        let dependencies = Dependencies(analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = PaymentMethodsViewModel(orderID: orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        viewModel.trackCollectByScanToPay()

        // Then
        assertEqual(analytics.receivedEvents, [WooAnalyticsStat.paymentsFlowCollect.rawValue])
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "scan_to_pay")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["order_id"] as? Int64, orderID)
    }

    func test_collect_event_is_tracked_when_collecting_payment() {
        // Given
        let analytics = MockAnalyticsProvider()
        let orderID: Int64 = 232
        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .success(()))
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(
            cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
            stores: stores,
            analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = PaymentMethodsViewModel(orderID: orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        viewModel.collectPayment(on: UIViewController(), useCase: useCase, onSuccess: {}, onFailure: {})

        // Then
        assertEqual(analytics.receivedEvents.last, WooAnalyticsStat.paymentsFlowCollect.rawValue)
        assertEqual(analytics.receivedProperties.last?["payment_method"] as? String, "card")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["order_id"] as? Int64, orderID)
    }

    func test_card_row_is_shown_for_eligible_order_and_country_even_when_ttp_is_not_supported() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storage = MockStorageManager()
        let configuration = CardPresentPaymentsConfiguration.init(country: "US")

        // When
        simulate(cardPaymentEligibility: true, tapToPayDeviceAvailability: false, on: stores)

        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = PaymentMethodsViewModel(siteID: 1212,
                                                orderID: 111,
                                                formattedTotal: "$5.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // Then
        XCTAssertTrue(viewModel.showPayWithCardRow)
        XCTAssertFalse(viewModel.showTapToPayRow)
    }

    func test_ttp_row_is_shown_for_eligible_order_and_country_when_ttp_is_supported_by_device_and_store() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storage = MockStorageManager()
        let configuration = CardPresentPaymentsConfiguration.init(country: "US")

        simulate(cardPaymentEligibility: true, tapToPayDeviceAvailability: true, on: stores)

        // When
        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = PaymentMethodsViewModel(siteID: 1212,
                                                orderID: 111,
                                                formattedTotal: "$5.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // Then
        XCTAssertTrue(viewModel.showPayWithCardRow)
        XCTAssertTrue(viewModel.showTapToPayRow)
    }

    func test_ttp_row_is_not_shown_for_eligible_order_and_country_when_ttp_is_supported_by_device_but_not_store() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storage = MockStorageManager()
        let configuration = CardPresentPaymentsConfiguration.init(country: "CA")

        simulate(cardPaymentEligibility: true, tapToPayDeviceAvailability: true, on: stores)

        // When
        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = PaymentMethodsViewModel(siteID: 1212,
                                                orderID: 111,
                                                formattedTotal: "$5.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // Then
        XCTAssertTrue(viewModel.showPayWithCardRow)
        XCTAssertFalse(viewModel.showTapToPayRow)
    }

    func test_card_rows_are_not_shown_when_there_is_an_error_checking_for_order_eligibility() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storage = MockStorageManager()
        let configuration = CardPresentPaymentsConfiguration.init(country: "US")
        stores.whenReceivingAction(ofType: OrderCardPresentPaymentEligibilityAction.self) { action in
            switch action {
            case let .orderIsEligibleForCardPresentPayment(_, _, _, completion):
                completion(.failure(NSError(domain: "Error", code: 0)))
            }
        }

        simulate(tapToPayDeviceAvailability: true, on: stores)

        // When
        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = PaymentMethodsViewModel(siteID: 1212,
                                                orderID: 111,
                                                formattedTotal: "$5.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // Then
        XCTAssertFalse(viewModel.showPayWithCardRow)
        XCTAssertFalse(viewModel.showTapToPayRow)
    }

    func test_card_rows_are_not_shown_for_non_eligible_order() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storage = MockStorageManager()
        let configuration = CardPresentPaymentsConfiguration.init(country: "US")

        simulate(cardPaymentEligibility: false, tapToPayDeviceAvailability: true, on: stores)

        // When
        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = PaymentMethodsViewModel(siteID: 1212,
                                                orderID: 111,
                                                formattedTotal: "$5.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // Then
        XCTAssertFalse(viewModel.showPayWithCardRow)
        XCTAssertFalse(viewModel.showTapToPayRow)
    }

    func test_card_rows_are_not_shown_for_eligible_order_but_ineligible_country() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storage = MockStorageManager()
        let configuration = CardPresentPaymentsConfiguration.init(country: "AQ")

        simulate(cardPaymentEligibility: true, tapToPayDeviceAvailability: true, on: stores)

        // When
        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = PaymentMethodsViewModel(siteID: 1212,
                                                orderID: 111,
                                                formattedTotal: "$5.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // Then
        XCTAssertFalse(viewModel.showPayWithCardRow)
        XCTAssertFalse(viewModel.showTapToPayRow)
    }

    func test_paymentLinkRow_is_hidden_if_payment_link_is_not_available() {
        // Given
        let viewModel = PaymentMethodsViewModel(paymentLink: nil,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false)

        // Then
        XCTAssertFalse(viewModel.showPaymentLinkRow)
        XCTAssertNil(viewModel.paymentLink)
    }

    func test_paymentLinkRow_is_shown_if_payment_link_is_available() {
        // Given
        let paymentURL = URL(string: "http://www.automattic.com")
        let viewModel = PaymentMethodsViewModel(paymentLink: paymentURL,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false)

        // Then
        XCTAssertTrue(viewModel.showPaymentLinkRow)
        XCTAssertNotNil(viewModel.paymentLink)
    }

    func test_scanToPayRow_is_hidden_if_payment_link_is_not_available() {
        // Given
        let viewModel = PaymentMethodsViewModel(paymentLink: nil,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false)

        // Then
        XCTAssertFalse(viewModel.showScanToPayRow)
        XCTAssertNil(viewModel.paymentLink)
    }

    func test_scanToPayRow_is_shown_if_payment_link_is_not_nil() {
        // Given
        let paymentURL = URL(string: "http://www.automattic.com")
        let viewModel = PaymentMethodsViewModel(paymentLink: paymentURL,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false)

        // Then
        XCTAssertTrue(viewModel.showScanToPayRow)
    }

    func test_view_model_attempts_created_notice_after_sharing_link() {
        // Given
        let noticeSubject = PassthroughSubject<SimplePaymentsNotice, Never>()
        let dependencies = Dependencies(presentNoticeSubject: noticeSubject)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        let receivedCompleted: Bool = waitFor { promise in
            noticeSubject.sink { intent in
                switch intent {
                case .error, .completed:
                    promise(false)
                case .created:
                    promise(true)
                }
            }
            .store(in: &self.subscriptions)
            viewModel.performLinkSharedTasks()
        }

        // Then
        XCTAssertTrue(receivedCompleted)
    }

    func test_view_model_attempts_created_notice_after_scan_to_pay() {
        // Given
        let noticeSubject = PassthroughSubject<SimplePaymentsNotice, Never>()
        let dependencies = Dependencies(presentNoticeSubject: noticeSubject)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        let receivedCompleted: Bool = waitFor { promise in
            noticeSubject.sink { intent in
                switch intent {
                case .error, .completed:
                    promise(false)
                case .created:
                    promise(true)
                }
            }
            .store(in: &self.subscriptions)
            viewModel.performScanToPayFinishedTasks()
        }

        // Then
        XCTAssertTrue(receivedCompleted)
    }

    func test_view_model_attempts_completed_notice_after_collecting_payment() {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleOrder(readOnlyOrder: .fake())

        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            switch action {
            case let .selectedPaymentGatewayAccount(onCompletion):
                onCompletion(PaymentGatewayAccount.fake())
            case .checkDeviceSupport(_, _, _, _):
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let noticeSubject = PassthroughSubject<SimplePaymentsNotice, Never>()
        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .success(()))
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(presentNoticeSubject: noticeSubject,
                                        cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
                                        stores: stores,
                                        storage: storage)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        let receivedCompleted: Bool = waitFor { promise in
            noticeSubject.sink { intent in
                switch intent {
                case .error, .created:
                    promise(false)
                case .completed:
                    promise(true)
                }
            }
            .store(in: &self.subscriptions)

            viewModel.collectPayment(on: UIViewController(), useCase: useCase, onSuccess: {}, onFailure: {})
        }

        // Then
        XCTAssertTrue(receivedCompleted)
    }

    func test_view_model_calls_onSuccess_after_collecting_payment() {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleOrder(readOnlyOrder: .fake())
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .selectedPaymentGatewayAccount(onCompletion) = action {
                onCompletion(PaymentGatewayAccount.fake())
            }
        }

        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .success(()))
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
                                        stores: stores,
                                        storage: storage)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        let calledOnSuccess: Bool = waitFor { promise in
            viewModel.collectPayment(on: UIViewController(),
                                     useCase: useCase,
                                     onSuccess: {
                promise(true)
            },
                                     onFailure: {})
        }

        // Then
        XCTAssertTrue(calledOnSuccess)
    }

    func test_view_model_updates_order_async_after_collecting_payment_successfully() throws {
        // Given
        let storage = MockStorageManager()
        let order = Order.fake().copy(status: .pending)
        storage.insertSampleOrder(readOnlyOrder: order)

        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .selectedPaymentGatewayAccount(onCompletion) = action {
                onCompletion(PaymentGatewayAccount.fake())
            }
        }

        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .success(()))
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
                                        stores: stores,
                                        storage: storage)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                isTapToPayOnIPhoneEnabled: false,
                                                dependencies: dependencies)

        // When
        let (siteID, orderID): (Int64, Int64) = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .retrieveOrder(siteID, orderID, _):
                    promise((siteID, orderID))
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }
            viewModel.collectPayment(on: UIViewController(), useCase: useCase, onSuccess: {}, onFailure: {})
        }

        // Then
        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
    }
}

private extension PaymentMethodsViewModelTests {
    private func simulate(cardPaymentEligibility: Bool, tapToPayDeviceAvailability: Bool, on stores: MockStoresManager) {
        simulate(cardPaymentEligibility: cardPaymentEligibility, on: stores)
        simulate(tapToPayDeviceAvailability: tapToPayDeviceAvailability, on: stores)
    }

    private func simulate(cardPaymentEligibility: Bool, on stores: MockStoresManager) {
        stores.whenReceivingAction(ofType: OrderCardPresentPaymentEligibilityAction.self) { action in
            switch action {
            case let .orderIsEligibleForCardPresentPayment(_, _, _, completion):
                completion(.success(cardPaymentEligibility))
            }
        }
    }

    private func simulate(tapToPayDeviceAvailability: Bool, on stores: MockStoresManager) {
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            switch action {
            case let .checkDeviceSupport(_, _, .localMobile, completion):
                completion(tapToPayDeviceAvailability)
            default:
                break
            }
        }
    }
}
