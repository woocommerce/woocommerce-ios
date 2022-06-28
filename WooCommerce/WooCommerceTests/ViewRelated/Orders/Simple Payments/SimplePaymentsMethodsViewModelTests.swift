import Foundation
import XCTest
import Combine
import Fakes

@testable import WooCommerce
@testable import Yosemite

private typealias Dependencies = SimplePaymentsMethodsViewModel.Dependencies

final class SimplePaymentsMethodsViewModelTests: XCTestCase {

    var subscriptions = Set<AnyCancellable>()

    func test_loading_is_enabled_while_marking_order_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(nil)
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let dependencies = Dependencies(stores: stores)
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
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
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
                                                       dependencies: dependencies)

        // When
        let loading: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .updateOrderStatus:
                    promise(viewModel.showLoadingIndicator)
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

    func test_onSuccess_is_invoked_after_order_is_marked_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let dependencies = Dependencies(stores: stores)
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
                                                       dependencies: dependencies)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(nil)
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
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
                                                       dependencies: dependencies)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(nil)
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
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
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
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let analytics = MockAnalyticsProvider()
        let dependencies = Dependencies(stores: stores,
                                        analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
                                                       dependencies: dependencies)

        // When
        viewModel.markOrderAsPaid(onSuccess: {})

        // Then
        assertEqual(analytics.receivedEvents.first, WooAnalyticsStat.paymentsFlowCompleted.rawValue)
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "cash")
        assertEqual(analytics.receivedProperties.first?["amount"] as? String, "$12.00")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
    }

    func test_completed_event_is_tracked_after_collecting_payment_successfully() {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleOrder(readOnlyOrder: .fake())
        storage.insertSamplePaymentGatewayAccount(readOnlyAccount: .fake())

        let analytics = MockAnalyticsProvider()
        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .success(()))
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(
            cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
            storage: storage,
            analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
                                                       dependencies: dependencies)

        // When
        viewModel.collectPayment(on: UIViewController(), useCase: useCase, onSuccess: {})

        // Then
        assertEqual(analytics.receivedEvents.last, WooAnalyticsStat.paymentsFlowCompleted.rawValue)
        assertEqual(analytics.receivedProperties.last?["payment_method"] as? String, "card")
        assertEqual(analytics.receivedProperties.last?["amount"] as? String, "$12.00")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
    }

    func test_completed_event_is_tracked_after_sharing_a_link() {
        // Given
        let analytics = MockAnalyticsProvider()
        let dependencies = Dependencies(analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
                                                       dependencies: dependencies)

        // When
        viewModel.performLinkSharedTasks()

        // Then
        assertEqual(analytics.receivedEvents.first, WooAnalyticsStat.paymentsFlowCompleted.rawValue)
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "payment_link")
        assertEqual(analytics.receivedProperties.first?["amount"] as? String, "$12.00")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
    }

    func test_failed_event_is_tracked_after_failing_to_mark_order_as_paid() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrderStatus(_, _, _, onCompletion):
                onCompletion(NSError(domain: "", code: 0, userInfo: nil))
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let analytics = MockAnalyticsProvider()
        let dependencies = Dependencies(stores: stores,
                                        analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
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
        storage.insertSamplePaymentGatewayAccount(readOnlyAccount: .fake())

        let analytics = MockAnalyticsProvider()
        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .failure(NSError(domain: "Error", code: 0, userInfo: nil)))
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(
            cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
            storage: storage,
            analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
                                                       dependencies: dependencies)

        // When
        viewModel.collectPayment(on: UIViewController(), useCase: useCase, onSuccess: {})

        // Then
        assertEqual(analytics.receivedEvents.last, WooAnalyticsStat.paymentsFlowFailed.rawValue)
        assertEqual(analytics.receivedProperties.last?["source"] as? String, "payment_method")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
    }

    func test_collect_event_is_tracked_when_paying_by_cash() {
        // Given
        let analytics = MockAnalyticsProvider()
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let dependencies = Dependencies(stores: stores,
                                        analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
                                                       dependencies: dependencies)

        // When
        viewModel.trackCollectByCash()

        // Then
        assertEqual(analytics.receivedEvents, [WooAnalyticsStat.paymentsFlowCollect.rawValue])
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "cash")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
    }

    func test_collect_event_is_tracked_when_sharing_payment_links() {
        // Given
        let analytics = MockAnalyticsProvider()
        let dependencies = Dependencies(analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
                                                       dependencies: dependencies)

        // When
        viewModel.trackCollectByPaymentLink()

        // Then
        assertEqual(analytics.receivedEvents, [WooAnalyticsStat.paymentsFlowCollect.rawValue])
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "payment_link")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
    }

    func test_collect_event_is_tracked_when_collecting_payment() {
        // Given
        let analytics = MockAnalyticsProvider()
        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .success(()))
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(
            cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
            stores: stores,
            analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
                                                       dependencies: dependencies)

        // When
        viewModel.collectPayment(on: UIViewController(), useCase: useCase, onSuccess: {})

        // Then
        assertEqual(analytics.receivedEvents.last, WooAnalyticsStat.paymentsFlowCollect.rawValue)
        assertEqual(analytics.receivedProperties.last?["payment_method"] as? String, "card")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
    }

    func test_card_row_is_shown_for_eligible_order_and_country() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storage = MockStorageManager()
        let configuration = CardPresentPaymentsConfiguration.init(country: "US")
        stores.whenReceivingAction(ofType: OrderCardPresentPaymentEligibilityAction.self) { action in
            switch action {
            case let .orderIsEligibleForCardPresentPayment(_, _, _, completion):
                completion(.success(true))
            }
        }

        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = SimplePaymentsMethodsViewModel(siteID: 1212, orderID: 111, formattedTotal: "$5.00", dependencies: dependencies)

        // Then
        XCTAssertTrue(viewModel.showPayWithCardRow)
    }

    func test_card_row_is_not_shown_when_there_is_an_error_checking_for_order_eligibility() {
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

        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = SimplePaymentsMethodsViewModel(siteID: 1212, orderID: 111, formattedTotal: "$5.00", dependencies: dependencies)

        // Then
        XCTAssertFalse(viewModel.showPayWithCardRow)
    }

    func test_card_row_is_not_shown_for_non_eligible_order() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storage = MockStorageManager()
        let configuration = CardPresentPaymentsConfiguration.init(country: "US")
        stores.whenReceivingAction(ofType: OrderCardPresentPaymentEligibilityAction.self) { action in
            switch action {
            case let .orderIsEligibleForCardPresentPayment(_, _, _, completion):
                completion(.success(false))
            }
        }

        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = SimplePaymentsMethodsViewModel(siteID: 1212, orderID: 111, formattedTotal: "$5.00", dependencies: dependencies)

        // Then
        XCTAssertFalse(viewModel.showPayWithCardRow)
    }

    func test_card_row_is_not_shown_for_eligible_order_but_ineligible_country() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storage = MockStorageManager()
        let configuration = CardPresentPaymentsConfiguration.init(country: "AQ")
        stores.whenReceivingAction(ofType: OrderCardPresentPaymentEligibilityAction.self) { action in
            switch action {
            case let .orderIsEligibleForCardPresentPayment(_, _, _, completion):
                completion(.success(true))
            }
        }

        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = SimplePaymentsMethodsViewModel(siteID: 1212, orderID: 111, formattedTotal: "$5.00", dependencies: dependencies)

        // Then
        XCTAssertFalse(viewModel.showPayWithCardRow)
    }

    func test_card_row_is_not_shown_for_non_cpp_eligible_order_payment_method() {
        // Given

        let storage = MockStorageManager()
        let orderItem = OrderItem.fake().copy(itemID: 1234,
                                              name: "Chocolate cake",
                                              productID: 678,
                                              quantity: 1.0)
        let cppEligibleOrder = Order.fake().copy(siteID: 1212,
                                                 orderID: 111,
                                                 status: .pending,
                                                 currency: "USD",
                                                 datePaid: nil,
                                                 total: "5.00",
                                                 paymentMethodID: "some_other_payment_method",
                                                 items: [orderItem])
        let nonSubscriptionProduct = Product.fake().copy(siteID: 1212,
                                                         productID: 678,
                                                         name: "Chocolate cake",
                                                         productTypeKey: "simple")

        storage.insertSampleProduct(readOnlyProduct: nonSubscriptionProduct)
        storage.insertSampleOrder(readOnlyOrder: cppEligibleOrder)

        let configuration = CardPresentPaymentsConfiguration.init(country: "US")

        let dependencies = Dependencies(storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = SimplePaymentsMethodsViewModel(siteID: 1212, orderID: 111, formattedTotal: "$5.00", dependencies: dependencies)

        // Then
        XCTAssertFalse(viewModel.showPayWithCardRow)
    }

    func test_card_row_is_not_shown_for_non_cpp_eligible_order_currency() {
        // Given

        let storage = MockStorageManager()
        let orderItem = OrderItem.fake().copy(itemID: 1234,
                                              name: "Chocolate cake",
                                              productID: 678,
                                              quantity: 1.0)
        let cppEligibleOrder = Order.fake().copy(siteID: 1212,
                                                 orderID: 111,
                                                 status: .pending,
                                                 currency: "ZZZ",
                                                 datePaid: nil,
                                                 total: "5.00",
                                                 paymentMethodID: "woocommerce_payments",
                                                 items: [orderItem])
        let nonSubscriptionProduct = Product.fake().copy(siteID: 1212,
                                                         productID: 678,
                                                         name: "Chocolate cake",
                                                         productTypeKey: "simple")

        storage.insertSampleProduct(readOnlyProduct: nonSubscriptionProduct)
        storage.insertSampleOrder(readOnlyOrder: cppEligibleOrder)

        let configuration = CardPresentPaymentsConfiguration.init(country: "US")

        let dependencies = Dependencies(storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = SimplePaymentsMethodsViewModel(siteID: 1212, orderID: 111, formattedTotal: "$5.00", dependencies: dependencies)

        // Then
        XCTAssertFalse(viewModel.showPayWithCardRow)
    }

    func test_paymentLinkRow_is_hidden_if_payment_link_is_not_available() {
        // Given
        let viewModel = SimplePaymentsMethodsViewModel(paymentLink: nil, formattedTotal: "$12.00")

        // Then
        XCTAssertFalse(viewModel.showPaymentLinkRow)
        XCTAssertNil(viewModel.paymentLink)
    }

    func test_paymentLinkRow_is_shown_if_payment_link_is_available() {
        // Given
        let paymentURL = URL(string: "http://www.automattic.com")
        let viewModel = SimplePaymentsMethodsViewModel(paymentLink: paymentURL, formattedTotal: "$12.00")

        // Then
        XCTAssertTrue(viewModel.showPaymentLinkRow)
        XCTAssertNotNil(viewModel.paymentLink)
    }

    func test_view_model_attempts_created_notice_after_sharing_link() {
        // Given
        let noticeSubject = PassthroughSubject<SimplePaymentsNotice, Never>()
        let dependencies = Dependencies(presentNoticeSubject: noticeSubject)
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
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

    func test_view_model_attempts_completed_notice_after_collecting_payment() {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleOrder(readOnlyOrder: .fake())
        storage.insertSamplePaymentGatewayAccount(readOnlyAccount: .fake())

        let noticeSubject = PassthroughSubject<SimplePaymentsNotice, Never>()
        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .success(()))
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(presentNoticeSubject: noticeSubject,
                                        cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
                                        storage: storage)
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
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

            viewModel.collectPayment(on: UIViewController(), useCase: useCase, onSuccess: {})
        }

        // Then
        XCTAssertTrue(receivedCompleted)
    }

    func test_view_model_calls_onSuccess_after_collecting_payment() {
        // Given
        let storage = MockStorageManager()
        storage.insertSampleOrder(readOnlyOrder: .fake())
        storage.insertSamplePaymentGatewayAccount(readOnlyAccount: .fake())

        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .success(()))
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
                                        storage: storage)
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
                                                       dependencies: dependencies)

        // When
        let calledOnSuccess: Bool = waitFor { promise in
            viewModel.collectPayment(on: UIViewController(), useCase: useCase, onSuccess: {
                promise(true)
            })
        }

        // Then
        XCTAssertTrue(calledOnSuccess)
    }

    func test_view_model_updates_order_async_after_collecting_payment_successfully() throws {
        // Given
        let storage = MockStorageManager()
        let order = Order.fake().copy(status: .pending)
        storage.insertSampleOrder(readOnlyOrder: order)
        storage.insertSamplePaymentGatewayAccount(readOnlyAccount: .fake())

        let stores = MockStoresManager(sessionManager: .testingInstance)

        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .success(()))
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
                                        stores: stores,
                                        storage: storage)
        let viewModel = SimplePaymentsMethodsViewModel(formattedTotal: "$12.00",
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
            viewModel.collectPayment(on: UIViewController(), useCase: useCase, onSuccess: {})
        }

        // Then
        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
    }
}
