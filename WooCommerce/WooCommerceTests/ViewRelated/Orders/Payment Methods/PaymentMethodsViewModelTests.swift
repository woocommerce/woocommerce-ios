import Foundation
import XCTest
import Combine
import Fakes
import WooFoundation

@testable import WooCommerce
@testable import Yosemite

private typealias Dependencies = PaymentMethodsViewModel.Dependencies

@MainActor
final class PaymentMethodsViewModelTests: XCTestCase {
    private var subscriptions = Set<AnyCancellable>()
    private var stores: MockStoresManager!
    private var storage: MockStorageManager!

    override func setUp() {
        super.setUp()

        stores = MockStoresManager(sessionManager: .testingInstance)
        storage = MockStorageManager()
        subscriptions = Set<AnyCancellable>()
    }

    override func tearDown() {
        super.tearDown()

        stores = nil
        storage = nil
    }

    func test_loading_is_enabled_while_marking_order_as_paid() async {
        // Given
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        storage.insertSampleOrder(readOnlyOrder: .fake())
        let dependencies = Dependencies(stores: stores, storage: storage)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // When
        let loadingStates: [Bool] = await waitForAsync { promise in
            viewModel.$showLoadingIndicator
                .dropFirst() // Initial value
                .collect(2)  // Collect toggle
                .first()
                .sink { loadingStates in
                    promise(loadingStates)
                }
                .store(in: &self.subscriptions)
            await viewModel.markOrderAsPaidByCash(with: nil)
        }

        // Then
        XCTAssertEqual(loadingStates, [true, false]) // Loading, then not loading.
    }

    func test_view_is_disabled_while_loading_is_enabled() async {
        // Given
        storage.insertSampleOrder(readOnlyOrder: .fake())
        let dependencies = Dependencies(stores: stores, storage: storage)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // When
        let loading: Bool = await waitForAsync { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .updateOrder:
                    promise(viewModel.showLoadingIndicator)
                case .retrieveOrder:
                    break
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }
            await viewModel.markOrderAsPaidByCash(with: nil)
        }

        // Then
        XCTAssertTrue(loading)
        XCTAssertTrue(viewModel.disableViewActions)
    }

    func test_view_model_updates_order_async_after_order_marked_as_paid() async throws {
        // Given
        let order = Order.fake().copy(status: .pending)
        storage.insertSampleOrder(readOnlyOrder: order)
        storage.insertSamplePaymentGatewayAccount(readOnlyAccount: .fake())

        let dependencies = Dependencies(stores: stores,
                                        storage: storage)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // When
        let (siteID, orderID): (Int64, Int64) = await waitForAsync { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .updateOrder(_, _, _, _, onCompletion):
                    onCompletion(.success(.fake()))
                case let .retrieveOrder(siteID, orderID, _):
                    promise((siteID, orderID))
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }
            await viewModel.markOrderAsPaidByCash(with: nil)
        }

        // Then
        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
    }

    func test_onSuccess_is_invoked_after_order_is_marked_as_paid() async {
        // Given
        storage.insertSampleOrder(readOnlyOrder: .fake())
        let dependencies = Dependencies(stores: stores, storage: storage)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When/Then
        await viewModel.markOrderAsPaidByCash(with: nil)
    }

    func test_mark_order_as_paid_by_cash_then_order_status_and_payment_method_fields_updated() async {
        // Given
        let siteID: Int64 = 10
        let orderID: Int64 = 123
        let order = Order.fake().copy(siteID: siteID, orderID: orderID)
        storage.insertSampleOrder(readOnlyOrder: order)
        let paymentGateway = PaymentGateway.defaultPayInPersonGateway(siteID: siteID).copy(title: "Pay in Person")
        storage.insertSamplePaymentGateway(readOnlyGateway: paymentGateway)
        let dependencies = Dependencies(stores: stores, storage: storage)
        let viewModel = PaymentMethodsViewModel(siteID: siteID,
                                                orderID: orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)
        var modifiedOrder: Order?
        var orderUpdateFields: [OrderUpdateField]?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, order, _, fields, onCompletion):
                modifiedOrder = order
                orderUpdateFields = fields
                onCompletion(.success(.fake()))
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When/Then
        await viewModel.markOrderAsPaidByCash(with: nil)

        XCTAssertEqual(modifiedOrder?.paymentMethodID, PaymentGateway.Constants.cashOnDeliveryGatewayID)
        XCTAssertEqual(modifiedOrder?.paymentMethodTitle, "Pay in Person")
        XCTAssertEqual(modifiedOrder?.status, .completed)
        XCTAssertEqual(orderUpdateFields, [.status, .paymentMethodID, .paymentMethodTitle])
    }

    func test_view_model_attempts_completed_notice_presentation_when_marking_an_order_as_paid() async {
        // Given
        storage.insertSampleOrder(readOnlyOrder: .fake())
        let noticeSubject = PassthroughSubject<PaymentMethodsNotice, Never>()
        let dependencies = Dependencies(presentNoticeSubject: noticeSubject, stores: stores, storage: storage)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        // When
        let receivedCompleted: Bool = await waitForAsync { promise in
            noticeSubject.sink { intent in
                switch intent {
                case .error, .created:
                    promise(false)
                case .completed:
                    promise(true)
                }
            }
            .store(in: &self.subscriptions)
            await viewModel.markOrderAsPaidByCash(with: nil)
        }

        // Then
        XCTAssertTrue(receivedCompleted)
    }

    func test_view_model_attempts_error_notice_presentation_when_failing_to_mark_order_as_paid() async {
        // Given
        storage.insertSampleOrder(readOnlyOrder: .fake())
        let noticeSubject = PassthroughSubject<PaymentMethodsNotice, Never>()
        let dependencies = Dependencies(presentNoticeSubject: noticeSubject, stores: stores, storage: storage)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "Error", code: 0)))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }

        // When
        let receivedError: Bool = await waitForAsync { promise in
            noticeSubject.sink { intent in
                switch intent {
                case .error:
                    promise(true)
                case .completed, .created:
                    promise(false)
                }
            }
            .store(in: &self.subscriptions)
            await viewModel.markOrderAsPaidByCash(with: nil)
        }

        // Then
        XCTAssertTrue(receivedError)
    }

    func test_completed_event_is_tracked_after_marking_order_as_paid() async {
        // Given
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let analytics = MockAnalyticsProvider()
        let orderID: Int64 = 232
        storage.insertSampleOrder(readOnlyOrder: .fake().copy(orderID: orderID))
        let dependencies = Dependencies(stores: stores,
                                        storage: storage,
                                        analytics: WooAnalytics(analyticsProvider: analytics),
                                        cardPresentPaymentsConfiguration: .init(country: .GB))
        let viewModel = PaymentMethodsViewModel(orderID: orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // When
        await viewModel.markOrderAsPaidByCash(with: nil)

        // Then
        assertEqual(analytics.receivedEvents.first, WooAnalyticsStat.paymentsFlowCompleted.rawValue)
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "cash")
        assertEqual(analytics.receivedProperties.first?["amount"] as? String, "$12.00")
        assertEqual(analytics.receivedProperties.first?["amount_normalized"] as? Int, 1200)
        assertEqual(analytics.receivedProperties.first?["country"] as? String, "GB")
        assertEqual(analytics.receivedProperties.first?["currency"] as? String, "USD")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["order_id"] as? Int64, orderID)
    }

    func test_completed_event_is_tracked_after_marking_order_as_paid_with_zero_decimals_currency() async {
        // Given
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let analytics = MockAnalyticsProvider()
        let currencySettings = CurrencySettings()
        currencySettings.currencyCode = .JPY
        let orderID: Int64 = 232
        storage.insertSampleOrder(readOnlyOrder: .fake().copy(orderID: orderID))
        let dependencies = Dependencies(stores: stores,
                                        storage: storage,
                                        analytics: WooAnalytics(analyticsProvider: analytics),
                                        cardPresentPaymentsConfiguration: .init(country: .GB),
                                        currencySettings: currencySettings)
        let viewModel = PaymentMethodsViewModel(orderID: orderID,
                                                formattedTotal: "¥12",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // When
        await viewModel.markOrderAsPaidByCash(with: nil)

        // Then
        assertEqual(analytics.receivedEvents.first, WooAnalyticsStat.paymentsFlowCompleted.rawValue)
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "cash")
        assertEqual(analytics.receivedProperties.first?["amount"] as? String, "¥12")
        assertEqual(analytics.receivedProperties.first?["amount_normalized"] as? Int, 12)
        assertEqual(analytics.receivedProperties.first?["country"] as? String, "GB")
        assertEqual(analytics.receivedProperties.first?["currency"] as? String, "JPY")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["order_id"] as? Int64, orderID)
    }

    func test_completed_event_is_tracked_after_collecting_payment_successfully() {
        // Given
        let insertOrder = Order.fake()
        storage.insertSampleOrder(readOnlyOrder: insertOrder)
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
                                                dependencies: dependencies)

        // When
        viewModel.collectPayment(using: .bluetoothScan, on: UIViewController(), useCase: useCase, onSuccess: {}, onFailure: {})

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

    func test_failed_event_is_tracked_after_failing_to_mark_order_as_paid() async {
        // Given
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, _, onCompletion):
                onCompletion(.failure(NSError(domain: "", code: 0, userInfo: nil)))
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let analytics = MockAnalyticsProvider()
        let currencySettings = CurrencySettings()
        currencySettings.currencyCode = .JPY
        storage.insertSampleOrder(readOnlyOrder: .fake())
        let dependencies = Dependencies(stores: stores,
                                        storage: storage,
                                        analytics: WooAnalytics(analyticsProvider: analytics),
                                        cardPresentPaymentsConfiguration: .init(country: .GB),
                                        currencySettings: currencySettings)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // When
        await viewModel.markOrderAsPaidByCash(with: nil)

        // Then
        assertEqual(analytics.receivedEvents.first, WooAnalyticsStat.paymentsFlowFailed.rawValue)
        assertEqual(analytics.receivedProperties.first?["source"] as? String, "payment_method")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["country"] as? String, "GB")
        assertEqual(analytics.receivedProperties.first?["currency"] as? String, "JPY")
    }

    func test_markOrderAsPaidByCash_when_passing_info_with_add_note_true_sends_note() async {
        // Given
        let cashPaymentInfo = OrderPaidByCashInfo(customerPaidAmount: "$50", changeGivenAmount: "$20", addNoteWithChangeData: true)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .updateOrder(_, _, _, _, onCompletion):
                onCompletion(.success(.fake()))
            case .retrieveOrder:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        var passedNote: String?
        stores.whenReceivingAction(ofType: OrderNoteAction.self) { action in
            switch action {
            case let .addOrderNote(_, _, _, note, onCompletion):
                passedNote = note
                onCompletion(nil, nil)
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        storage.insertSampleOrder(readOnlyOrder: .fake())
        let dependencies = Dependencies(stores: stores, storage: storage)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // When
        await viewModel.markOrderAsPaidByCash(with: cashPaymentInfo)

        // Then
        let expectedNote = String.localizedStringWithFormat(Localization.orderPaidByCashNoteText,
                                                            cashPaymentInfo.customerPaidAmount,
                                                            cashPaymentInfo.changeGivenAmount)
        XCTAssertEqual(passedNote, expectedNote)
    }

    func test_failed_event_is_tracked_after_failing_to_collect_payment() {
        // Given
        storage.insertSampleOrder(readOnlyOrder: .fake())
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
                                                dependencies: dependencies)

        // When
        viewModel.collectPayment(using: .bluetoothScan, on: UIViewController(), useCase: useCase, onSuccess: {}, onFailure: {})

        // Then
        assertEqual(analytics.receivedEvents.last, WooAnalyticsStat.paymentsFlowFailed.rawValue)
        assertEqual(analytics.receivedProperties.last?["source"] as? String, "payment_method")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
    }

    func test_collect_event_is_tracked_when_paying_by_cash() {
        // Given
        let analytics = MockAnalyticsProvider()
        let orderID: Int64 = 232
        let currencySettings = CurrencySettings()
        currencySettings.currencyCode = .JPY
        let dependencies = Dependencies(stores: stores,
                                        analytics: WooAnalytics(analyticsProvider: analytics),
                                        cardPresentPaymentsConfiguration: .init(country: .JP),
                                        currencySettings: currencySettings)
        let viewModel = PaymentMethodsViewModel(orderID: orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // When
        viewModel.trackCollectByCash()

        // Then
        assertEqual(analytics.receivedEvents, [WooAnalyticsStat.paymentsFlowCollect.rawValue])
        assertEqual(analytics.receivedProperties.first?["payment_method"] as? String, "cash")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["order_id"] as? Int64, orderID)
        assertEqual(analytics.receivedProperties.first?["country"] as? String, "JP")
        assertEqual(analytics.receivedProperties.first?["currency"] as? String, "JPY")
    }

    func test_collect_event_is_tracked_when_sharing_payment_links() {
        // Given
        let analytics = MockAnalyticsProvider()
        let orderID: Int64 = 232
        let dependencies = Dependencies(analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = PaymentMethodsViewModel(orderID: orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
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
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(
            cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
            stores: stores,
            analytics: WooAnalytics(analyticsProvider: analytics))
        let viewModel = PaymentMethodsViewModel(orderID: orderID,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // When
        viewModel.collectPayment(using: .bluetoothScan, on: UIViewController(), useCase: useCase, onSuccess: {}, onFailure: {})

        // Then
        assertEqual(analytics.receivedEvents.last, WooAnalyticsStat.paymentsFlowCollect.rawValue)
        assertEqual(analytics.receivedProperties.last?["payment_method"] as? String, "card")
        assertEqual(analytics.receivedProperties.first?["flow"] as? String, "simple_payment")
        assertEqual(analytics.receivedProperties.first?["order_id"] as? Int64, orderID)
    }

    func test_card_row_is_shown_for_eligible_order_and_country_even_when_ttp_is_not_supported() {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .US)

        // When
        simulate(cardPaymentEligibility: true, tapToPayDeviceAvailability: false, on: stores)

        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = PaymentMethodsViewModel(siteID: 1212,
                                                orderID: 111,
                                                formattedTotal: "$5.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // Then
        XCTAssertTrue(viewModel.showPayWithCardRow)
        XCTAssertFalse(viewModel.showTapToPayRow)
    }

    func test_ttp_row_is_shown_for_eligible_order_and_country_when_ttp_is_supported_by_device_and_store() {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .US)

        simulate(cardPaymentEligibility: true, tapToPayDeviceAvailability: true, on: stores)

        // When
        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = PaymentMethodsViewModel(siteID: 1212,
                                                orderID: 111,
                                                formattedTotal: "$5.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // Then
        XCTAssertTrue(viewModel.showPayWithCardRow)
        XCTAssertTrue(viewModel.showTapToPayRow)
    }

    func test_ttp_row_is_not_shown_for_eligible_order_and_country_when_ttp_is_supported_by_device_but_not_store() {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .CA)

        simulate(cardPaymentEligibility: true, tapToPayDeviceAvailability: true, on: stores)

        // When
        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = PaymentMethodsViewModel(siteID: 1212,
                                                orderID: 111,
                                                formattedTotal: "$5.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // Then
        XCTAssertTrue(viewModel.showPayWithCardRow)
        XCTAssertFalse(viewModel.showTapToPayRow)
    }

    func test_card_rows_are_not_shown_when_there_is_an_error_checking_for_order_eligibility() {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .US)
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
                                                dependencies: dependencies)

        // Then
        XCTAssertFalse(viewModel.showPayWithCardRow)
        XCTAssertFalse(viewModel.showTapToPayRow)
    }

    func test_card_rows_are_not_shown_for_non_eligible_order() {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .US)

        simulate(cardPaymentEligibility: false, tapToPayDeviceAvailability: true, on: stores)

        // When
        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = PaymentMethodsViewModel(siteID: 1212,
                                                orderID: 111,
                                                formattedTotal: "$5.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // Then
        XCTAssertFalse(viewModel.showPayWithCardRow)
        XCTAssertFalse(viewModel.showTapToPayRow)
    }

    func test_card_rows_are_not_shown_for_eligible_order_but_ineligible_country() {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .AQ)

        simulate(cardPaymentEligibility: true, tapToPayDeviceAvailability: true, on: stores)

        // When
        let dependencies = Dependencies(stores: stores, storage: storage, cardPresentPaymentsConfiguration: configuration)
        let viewModel = PaymentMethodsViewModel(siteID: 1212,
                                                orderID: 111,
                                                formattedTotal: "$5.00",
                                                flow: .simplePayment,
                                                dependencies: dependencies)

        // Then
        XCTAssertFalse(viewModel.showPayWithCardRow)
        XCTAssertFalse(viewModel.showTapToPayRow)
    }

    func test_paymentLinkRow_is_hidden_if_payment_link_is_not_available() {
        // Given
        let viewModel = PaymentMethodsViewModel(paymentLink: nil,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment)

        // Then
        XCTAssertFalse(viewModel.showPaymentLinkRow)
        XCTAssertNil(viewModel.paymentLink)
    }

    func test_paymentLinkRow_is_shown_if_payment_link_is_available() {
        // Given
        let paymentURL = URL(string: "http://www.automattic.com")
        let viewModel = PaymentMethodsViewModel(paymentLink: paymentURL,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment)

        // Then
        XCTAssertTrue(viewModel.showPaymentLinkRow)
        XCTAssertNotNil(viewModel.paymentLink)
    }

    func test_scanToPayRow_is_hidden_if_payment_link_is_not_available() {
        // Given
        let viewModel = PaymentMethodsViewModel(paymentLink: nil,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment)

        // Then
        XCTAssertFalse(viewModel.showScanToPayRow)
        XCTAssertNil(viewModel.paymentLink)
    }

    func test_scanToPayRow_is_shown_if_payment_link_is_not_nil() {
        // Given
        let paymentURL = URL(string: "http://www.automattic.com")
        let viewModel = PaymentMethodsViewModel(paymentLink: paymentURL,
                                                formattedTotal: "$12.00",
                                                flow: .simplePayment)

        // Then
        XCTAssertTrue(viewModel.showScanToPayRow)
    }

    func test_view_model_attempts_created_notice_after_sharing_link() {
        // Given
        let noticeSubject = PassthroughSubject<PaymentMethodsNotice, Never>()
        let dependencies = Dependencies(presentNoticeSubject: noticeSubject)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
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
        let noticeSubject = PassthroughSubject<PaymentMethodsNotice, Never>()
        let dependencies = Dependencies(presentNoticeSubject: noticeSubject)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
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
        storage.insertSampleOrder(readOnlyOrder: .fake())

        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            switch action {
            case let .selectedPaymentGatewayAccount(onCompletion):
                onCompletion(PaymentGatewayAccount.fake())
            case .checkDeviceSupport, .observeConnectedReaders:
                break
            default:
                XCTFail("Unexpected action: \(action)")
            }
        }

        let noticeSubject = PassthroughSubject<PaymentMethodsNotice, Never>()
        let useCase = MockCollectOrderPaymentUseCase(onCollectResult: .success(()))
        let onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()
        let dependencies = Dependencies(presentNoticeSubject: noticeSubject,
                                        cardPresentPaymentsOnboardingPresenter: onboardingPresenter,
                                        stores: stores,
                                        storage: storage)
        let viewModel = PaymentMethodsViewModel(formattedTotal: "$12.00",
                                                flow: .simplePayment,
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

            viewModel.collectPayment(using: .bluetoothScan, on: UIViewController(), useCase: useCase, onSuccess: {}, onFailure: {})
        }

        // Then
        XCTAssertTrue(receivedCompleted)
    }

    func test_view_model_calls_onSuccess_after_collecting_payment() {
        // Given
        storage.insertSampleOrder(readOnlyOrder: .fake())
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
                                                dependencies: dependencies)

        // When
        let calledOnSuccess: Bool = waitFor { promise in
            viewModel.collectPayment(using: .bluetoothScan,
                                     on: UIViewController(),
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
        let order = Order.fake().copy(status: .pending)
        storage.insertSampleOrder(readOnlyOrder: order)

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
                                                dependencies: dependencies)

        // When
        let (siteID, orderID): (Int64, Int64) = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .retrieveOrder(siteID, orderID, _):
                    promise((siteID, orderID))
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }
            viewModel.collectPayment(using: .bluetoothScan, on: UIViewController(), useCase: useCase, onSuccess: {}, onFailure: {})
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
            case let .checkDeviceSupport(_, _, .localMobile, _, completion):
                completion(tapToPayDeviceAvailability)
            default:
                break
            }
        }
    }
}

private extension PaymentMethodsViewModelTests {
    enum Localization {
        static let orderPaidByCashNoteText = NSLocalizedString("paymentMethods.orderPaidByCashNoteText.note",
                                                               value: "The order was paid by cash. Customer paid %1$@. The change due was %2$@.",
                                                               comment: "Title for the cash tender view. Reads like Cash $34.45")
    }
}
