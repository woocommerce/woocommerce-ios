import PointOfSale
import Codegen
import Combine
import Networking
import TestKit
import UIKit
import XCTest
import Yosemite
import WooFoundation
@testable import WooCommerce

@MainActor
final class CollectOrderPaymentUseCaseTests: XCTestCase {
    private let defaultSiteID: Int64 = 122
    private let defaultOrderID: Int64 = 322

    private var stores: MockStoresManager!
    private var alertsPresenter: MockCardPresentPaymentAlertsPresenter!
    private var mockPreflightController: MockCardPresentPaymentPreflightController!
    private var mockAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker!
    private var mockPaymentOrchestrator: MockPaymentCaptureOrchestrator!
    private var useCase: CollectOrderPaymentUseCase<TapToPayCardReaderPaymentAlertsProvider,
                                                        BluetoothCardReaderPaymentAlertsProvider,
                                                        MockCardPresentPaymentAlertsPresenter>!
    private var receiptEligibilityUseCase: MockReceiptEligibilityUseCase!
    private var notificationCenter: NotificationCenter!
    private var applicationState: UIApplication.State!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.reset()
        mockAnalyticsTracker = MockCollectOrderPaymentAnalyticsTracker()
        mockPaymentOrchestrator = MockPaymentCaptureOrchestrator()
        alertsPresenter = MockCardPresentPaymentAlertsPresenter()
        mockPreflightController = MockCardPresentPaymentPreflightController()
        receiptEligibilityUseCase = MockReceiptEligibilityUseCase()
        notificationCenter = NotificationCenter()
        applicationState = .active

        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
        setUpUseCase(order: order)
    }

    private func setUpUseCase(order: Order,
                              configuration: CardPresentPaymentsConfiguration = Mocks.configuration,
                              analyticsTracker: CollectOrderPaymentAnalyticsTracking? = nil) {
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .retrieveOrderRemotely(_, _, let completion):
                completion(.success(order))
            default:
                break
            }
        }

        useCase = CollectOrderPaymentUseCase(siteID: defaultSiteID,
                                             order: order,
                                             formattedAmount: "1.5",
                                             rootViewController: MockViewControllerPresenting(),
                                             configuration: configuration,
                                             stores: stores,
                                             paymentOrchestrator: mockPaymentOrchestrator,
                                             alertsPresenter: alertsPresenter,
                                             tapToPayAlertsProvider: TapToPayCardReaderPaymentAlertsProvider(),
                                             bluetoothAlertsProvider: BluetoothCardReaderPaymentAlertsProvider(transactionType: .collectPayment),
                                             preflightController: mockPreflightController,
                                             analyticsTracker: analyticsTracker ?? mockAnalyticsTracker,
                                             receiptEligibilityUseCase: receiptEligibilityUseCase,
                                             notificationCenter: notificationCenter,
                                             applicationStateProvider: { [weak self] in self?.applicationState ?? .inactive })
    }

    func test_retryApproach_when_paymentCapture_fails_with_paymentIntentIdMissing_then_dontRetry() {
        // Given
        let error = CardReaderServiceError.paymentCapture(underlyingError: .paymentIntentIdMissing)

        // When
        let retryApproach = error.retryApproach

        // Then
        guard case .dontRetry = retryApproach else {
            return XCTFail("Expected .dontRetry, got \(retryApproach)")
        }
    }

    func test_cancelling_reader_connection_triggers_onCancel_and_tracks_collectPaymentCanceled_event() throws {
        // Given

        // When
        let _: Void = waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan,
                                        channel: .storeManagement,
                                        onFailure: { _ in }, onCancel: {
                promise(())
            }, onPaymentCompletion: {}, onCompleted: {})
            self.mockPreflightController.cancelConnection(readerModel: Mocks.cardReaderModel, gatewayID: Mocks.paymentGatewayAccount, source: .foundReader)
        }

        // Then
        XCTAssertTrue(mockAnalyticsTracker.didCallTrackPaymentCancelation)
        assertEqual(.foundReader, mockAnalyticsTracker.spyPaymentCancelationSource)
    }

    func test_collectPayment_canceledWhileValidatingOrder_doesNotStartPaymentAfterValidationCompletes() async throws {
        // Given
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
        var orderRetrievalCompletion: ((Result<Order, Error>) -> Void)?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            guard case let .retrieveOrderRemotely(_, _, completion) = action else { return }
            orderRetrievalCompletion = completion
        }

        let collected = expectation(description: "Payment must not start after cancellation")
        collected.isInverted = true
        mockPaymentOrchestrator.mockCollectPaymentHandler = { _, _, _, _, _, _, _ in
            collected.fulfill()
        }

        let canceled = expectation(description: "Payment flow canceled")
        useCase.collectPayment(using: .tapToPay,
                               channel: .storeManagement,
                               onFailure: { _ in },
                               onCancel: { canceled.fulfill() },
                               onPaymentCompletion: {},
                               onCompleted: {})
        mockPreflightController.completeConnection(reader: MockCardReader.tapToPay(), gatewayID: Mocks.paymentGatewayAccount)

        let validatingOrderAlert = try XCTUnwrap(alertsPresenter.spyPresentedAlertViewModels.last)

        // When
        validatingOrderAlert.didTapSecondaryButton(in: nil)
        await fulfillment(of: [canceled], timeout: Constants.expectationTimeout)
        let completeRetrieval = try XCTUnwrap(orderRetrievalCompletion)
        completeRetrieval(.success(order))

        // Then
        await fulfillment(of: [collected], timeout: Constants.expectationTimeout)
        XCTAssertFalse(mockPaymentOrchestrator.spyDidCallCollectPayment)
    }

    func test_cancel_when_sdk_completion_is_delayed_then_clears_confirmation_before_next_collection() async throws {
        // Given
        let analytics = MockPOSAnalytics()
        var milliseconds = 0
        let tracker = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, monotonicMilliseconds: { milliseconds })
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
        setUpUseCase(order: order, analyticsTracker: tracker)
        tracker.trackCheckoutTapped()
        tracker.prepareForCardPayment(order: POSPaymentAnalyticsOrder(orderID: defaultOrderID,
                                                                     currency: "USD", total: "1.5", paymentMethodID: ""))
        mockPaymentOrchestrator.mockCollectPaymentHandler = { _, onWaitingForInput, _, _, _, onConfirmed, _ in
            onWaitingForInput(.tap)
            milliseconds = 100
            onConfirmed(.fake())
        }
        var finishCancellation: ((Result<Void, Error>) -> Void)?
        let cancellationRequested = expectation(description: "SDK cancellation requested")
        mockPaymentOrchestrator.mockCancelPaymentHandler = {
            finishCancellation = $0
            cancellationRequested.fulfill()
        }
        useCase.collectPayment(using: .bluetoothScan, channel: .pos,
                               onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {}, onCompleted: {})
        await waitForPaymentCollection {
            mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }
        XCTAssertTrue(mockPaymentOrchestrator.spyDidCallCollectPayment)
        let waitingAlert = try XCTUnwrap(alertsPresenter.spyPresentedAlertViewModels.last)
        // When
        milliseconds = 150
        waitingAlert.didTapSecondaryButton(in: ImmediateDismissViewController())
        await fulfillment(of: [cancellationRequested], timeout: Constants.expectationTimeout)
        let complete = try XCTUnwrap(finishCancellation)
        // Then
        milliseconds = 200
        tracker.trackPaymentFailure(with: TestError.cancellationFailed)
        XCTAssertNil(analytics.events.last?.properties["pos_time_since_payment_confirmed_ms"])
        // When
        mockPaymentOrchestrator.spyProcessingCompletion?(.fake())
        milliseconds = 225
        tracker.trackProcessingCompletion(intent: .fake(), recordPaymentConfirmation: true)
        milliseconds = 250
        complete(.success(()))
        // Then
        let cancellation = try XCTUnwrap(analytics.events.last)
        XCTAssertEqual(cancellation.eventName, "card_present_collect_payment_canceled")
        XCTAssertNil(cancellation.properties["sync_strategy"])
        XCTAssertFalse(cancellation.properties.keys.contains { ($0 as? String)?.hasPrefix("pos_time_since_") == true })
        // When
        milliseconds = 300
        tracker.trackPaymentFailure(with: TestError.cancellationFailed)
        // Then
        XCTAssertEqual(analytics.events.last?.properties["pos_time_since_payment_confirmed_ms"] as? Int, 75)
    }

    func test_interac_confirmation_during_cancellation_when_no_newer_pos_confirmation_then_preserves_legacy_event_without_timing() async throws {
        try await assertInteracConfirmationDuringCancellation(newerPOSConfirmation: false)
    }

    func test_interac_confirmation_during_cancellation_when_newer_pos_confirmation_exists_then_preserves_event_and_timestamp() async throws {
        try await assertInteracConfirmationDuringCancellation(newerPOSConfirmation: true)
    }

    func test_interac_confirmation_during_cancellation_when_non_pos_then_preserves_legacy_event() async throws {
        // Given
        let provider = MockAnalyticsProvider()
        let analytics = WooAnalytics(analyticsProvider: provider, consent: MockAnalyticsConsent())
        let tracker = CollectOrderPaymentAnalytics(siteID: defaultSiteID, analytics: analytics,
                                                  configuration: CardPresentPaymentsConfiguration(country: .CA))
        let pending = try await beginCancellationWithHeldCallback(analyticsTracker: tracker, channel: .storeManagement)
        // When
        pending.confirm(PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: .interacPresent(details: .fake()))]))
        pending.finishCancellation(.failure(TestError.cancellationFailed))
        // Then
        XCTAssertEqual(provider.receivedEvents, ["card_interac_collect_payment_success"])
        let properties = try XCTUnwrap(provider.receivedProperties.last)
        XCTAssertEqual(properties["country"] as? String, "CA")
        XCTAssertEqual(properties["site_id"] as? Int64, defaultSiteID)
        XCTAssertNil(properties["sync_strategy"])
        XCTAssertFalse(properties.keys.contains { ($0 as? String)?.hasPrefix("pos_time_since_") == true })
    }

    func test_preflight_cancellation_when_another_collection_has_confirmed_then_preserves_confirmation() {
        // Given
        let analytics = MockPOSAnalytics()
        var milliseconds = 0
        let tracker = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, monotonicMilliseconds: { milliseconds })
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
        setUpUseCase(order: order, analyticsTracker: tracker)
        useCase.collectPayment(using: .bluetoothScan, channel: .pos,
                               onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {}, onCompleted: {})
        tracker.trackCheckoutTapped()
        tracker.trackProcessingCompletion(intent: .fake(), recordPaymentConfirmation: true)
        // When
        mockPreflightController.cancelConnection(readerModel: nil, gatewayID: nil, source: .foundReader)
        milliseconds = 100
        tracker.trackPaymentFailure(with: TestError.cancellationFailed)
        // Then
        XCTAssertEqual(analytics.events.last?.properties["pos_time_since_payment_confirmed_ms"] as? Int, 100)
    }

    func test_collectPayment_canceledWhilePreparingReader_ignoresSubsequentReaderEvents() throws {
        // Given
        var presentedAlertCountAfterCancellation: Int?
        mockPaymentOrchestrator.mockCollectPaymentHandler = { onPreparingReader,
                                                              onWaitingForInput,
                                                              _,
                                                              _,
                                                              _,
                                                              _,
                                                              _ in
            self.alertsPresenter.onPresentCalled = { viewModel in
                viewModel.didTapSecondaryButton(in: nil)
            }
            onPreparingReader()
            presentedAlertCountAfterCancellation = self.alertsPresenter.spyPresentedAlertViewModels.count
            onWaitingForInput(.tap)
        }

        let canceled = expectation(description: "Payment flow canceled")
        useCase.collectPayment(using: .tapToPay,
                               channel: .storeManagement,
                               onFailure: { _ in },
                               onCancel: { canceled.fulfill() },
                               onPaymentCompletion: {},
                               onCompleted: {})
        mockPreflightController.completeConnection(reader: MockCardReader.tapToPay(), gatewayID: Mocks.paymentGatewayAccount)

        // When
        wait(for: [canceled], timeout: Constants.expectationTimeout)

        // Then
        XCTAssertEqual(alertsPresenter.spyPresentedAlertViewModels.count, try XCTUnwrap(presentedAlertCountAfterCancellation))
    }

    func test_collectPayment_successfulCancellationAfterTapToPayWasShown_requiresConfirmationBeforeCompleting() async throws {
        // Given
        applicationState = .inactive
        var didCancelFlow = false
        mockPaymentOrchestrator.mockCollectPaymentHandler = { onPreparingReader, _, _, _, _, _, onCompletion in
            self.alertsPresenter.onPresentCalled = { viewModel in
                self.alertsPresenter.onPresentCalled = nil
                viewModel.didTapSecondaryButton(in: nil)
            }
            onPreparingReader()
            onCompletion(.failure(CardReaderServiceError.paymentMethodCollection(underlyingError: .commandCancelled(from: .app))))
        }

        // When
        useCase.collectPayment(using: .tapToPay,
                               channel: .storeManagement,
                               onFailure: { _ in },
                               onCancel: { didCancelFlow = true },
                               onPaymentCompletion: {},
                               onCompleted: {})
        await waitForPaymentCollection {
            mockPreflightController.completeConnection(reader: MockCardReader.tapToPay(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertFalse(didCancelFlow)
        XCTAssertEqual(alertsPresenter.spyDismissCallCount, 0)

        // When
        applicationState = .active
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        // Then
        XCTAssertFalse(didCancelFlow)
        let confirmation = try XCTUnwrap(alertsPresenter.spyPresentedAlertViewModels.last as? CardPresentModalTapToPayPaymentCancelled)
        XCTAssertEqual(confirmation.topTitle, "Payment canceled")
        XCTAssertEqual(confirmation.bottomTitle, "No payment was taken.")
        XCTAssertEqual(confirmation.bottomSubtitle, "The Tap to Pay checkmark and sound only confirmed that the card was read.")

        // When
        confirmation.didTapPrimaryButton(in: nil)

        // Then
        XCTAssertTrue(didCancelFlow)
    }

    func test_collectPayment_when_app_reactivates_before_slow_cancellation_completes_still_requires_confirmation() async throws {
        // Given
        var cancellationCompletion: ((Result<Void, Error>) -> Void)?
        mockPaymentOrchestrator.mockCancelPaymentHandler = { completion in
            cancellationCompletion = completion
        }
        var didCancelFlow = false
        mockPaymentOrchestrator.mockCollectPaymentHandler = { onPreparingReader, _, _, _, _, _, _ in
            self.alertsPresenter.onPresentCalled = { viewModel in
                self.alertsPresenter.onPresentCalled = nil
                viewModel.didTapSecondaryButton(in: nil)
            }
            onPreparingReader()
        }

        useCase.collectPayment(using: .tapToPay,
                               channel: .storeManagement,
                               onFailure: { _ in },
                               onCancel: { didCancelFlow = true },
                               onPaymentCompletion: {},
                               onCompleted: {})
        await waitForPaymentCollection {
            mockPreflightController.completeConnection(reader: MockCardReader.tapToPay(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // When
        applicationState = .inactive
        notificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
        applicationState = .active
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        try XCTUnwrap(cancellationCompletion)(.success(()))

        // Then
        XCTAssertFalse(didCancelFlow)
        let confirmation = try XCTUnwrap(alertsPresenter.spyPresentedAlertViewModels.last as? CardPresentModalTapToPayPaymentCancelled)

        // When
        confirmation.didTapPrimaryButton(in: nil)

        // Then
        XCTAssertTrue(didCancelFlow)
    }

    func test_collectPayment_failedCancellation_keepsPaymentFlowActive() async {
        // Given
        mockPaymentOrchestrator.mockCancelPaymentResult = .failure(TestError.cancellationFailed)
        var didCancelFlow = false
        var didPresentProcessingAfterFailedCancellation = false
        mockPaymentOrchestrator.mockCollectPaymentHandler = { onPreparingReader,
                                                              _,
                                                              onProcessingMessage,
                                                              _,
                                                              _,
                                                              _,
                                                              _ in
            self.alertsPresenter.onPresentCalled = { viewModel in
                self.alertsPresenter.onPresentCalled = nil
                viewModel.didTapSecondaryButton(in: nil)
            }
            onPreparingReader()
            let alertCountAfterCancellation = self.alertsPresenter.spyPresentedAlertViewModels.count
            onProcessingMessage()
            didPresentProcessingAfterFailedCancellation =
                self.alertsPresenter.spyPresentedAlertViewModels.count == alertCountAfterCancellation + 1
        }

        // When
        useCase.collectPayment(using: .tapToPay,
                               channel: .storeManagement,
                               onFailure: { _ in },
                               onCancel: { didCancelFlow = true },
                               onPaymentCompletion: {},
                               onCompleted: {})
        await waitForPaymentCollection {
            mockPreflightController.completeConnection(reader: MockCardReader.tapToPay(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertFalse(didCancelFlow)
        XCTAssertTrue(didPresentProcessingAfterFailedCancellation)
    }

    func test_collectPayment_processing_completion_tracks_payment_success_event() throws {
        // Given
        let interacPaymentMethod = PaymentMethod.interacPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: interacPaymentMethod)])
        mockSuccessfulCardPresentPaymentActions(intent: intent,
                                                capturedPaymentData: CardPresentCapturedPaymentData(paymentMethod: interacPaymentMethod,
                                                                                                    receiptParameters: .fake()))

        // When
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, channel: .storeManagement, onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {
                promise(())
            }, onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssert(mockAnalyticsTracker.didCallTrackSuccessfulPayment)
        assertEqual(interacPaymentMethod, mockAnalyticsTracker.spyTrackSuccessfulPaymentCapturedPaymentData?.paymentMethod)
    }

    func test_collectPayment_enables_terminal_payment_preparation_when_route_is_available_for_Canada() throws {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .CA)
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
        setUpUseCase(order: order, configuration: configuration)
        mockTerminalPaymentPreparationRoute(isAvailable: true)

        let interacPaymentMethod = PaymentMethod.interacPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: interacPaymentMethod)])
        mockSuccessfulCardPresentPaymentActions(intent: intent,
                                                capturedPaymentData: CardPresentCapturedPaymentData(paymentMethod: interacPaymentMethod,
                                                                                                    receiptParameters: .fake()))

        // When
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, channel: .storeManagement, onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {
                promise(())
            }, onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertEqual(mockPaymentOrchestrator.spyTerminalPaymentPreparationEnabled, true)
    }

    func test_collectPayment_disables_terminal_payment_preparation_when_route_is_not_available_for_Canada() throws {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .CA)
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
        setUpUseCase(order: order, configuration: configuration)
        mockTerminalPaymentPreparationRoute(isAvailable: false)

        let interacPaymentMethod = PaymentMethod.interacPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: interacPaymentMethod)])
        mockSuccessfulCardPresentPaymentActions(intent: intent,
                                                capturedPaymentData: CardPresentCapturedPaymentData(paymentMethod: interacPaymentMethod,
                                                                                                    receiptParameters: .fake()))

        // When
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, channel: .storeManagement, onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {
                promise(())
            }, onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertEqual(mockPaymentOrchestrator.spyTerminalPaymentPreparationEnabled, false)
    }

    func test_collectPayment_enables_terminal_payment_preparation_without_checking_route_for_Australia() throws {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .AU)
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
        setUpUseCase(order: order, configuration: configuration)
        mockUnexpectedTerminalPaymentPreparationRouteCheck()

        let eftposPaymentMethod = PaymentMethod.cardPresent(details: CardPresentTransactionDetails(last4: "0978",
                                                                                                   expMonth: 12,
                                                                                                   expYear: 2030,
                                                                                                   cardholderName: nil,
                                                                                                   brand: .eftposAu,
                                                                                                   generatedCard: nil,
                                                                                                   receipt: nil,
                                                                                                   emvAuthData: nil,
                                                                                                   wallet: nil,
                                                                                                   network: nil))
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: eftposPaymentMethod)])
        mockSuccessfulCardPresentPaymentActions(intent: intent,
                                                capturedPaymentData: CardPresentCapturedPaymentData(paymentMethod: eftposPaymentMethod,
                                                                                                    receiptParameters: .fake()))

        // When
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, channel: .storeManagement, onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {
                promise(())
            }, onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertEqual(mockPaymentOrchestrator.spyTerminalPaymentPreparationEnabled, true)
    }

    func test_collectPayment_success_with_customer_then_modal_presented_with_email() throws {
        // Given we have an order with a customer
        let email = "test@test.com"
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5", billingAddress: Address.fake().copy(email: email))

        setUpUseCase(order: order)
        let interacPaymentMethod = PaymentMethod.interacPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: interacPaymentMethod)])
        mockSuccessfulCardPresentPaymentActions(intent: intent,
                                                capturedPaymentData: CardPresentCapturedPaymentData(paymentMethod: interacPaymentMethod,
                                                                                                    receiptParameters: .fake()))

        // When we make a successful payment
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, channel: .storeManagement, onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {
                promise(())
            }, onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then we should present a modal with the email
        let lastAlert = alertsPresenter.spyPresentedAlertViewModels.last as? CardPresentModalSuccessEmailSent
        XCTAssert(lastAlert?.bottomAttributedTitle?.string.contains(email) == true)
    }

    // MARK: - Failure cases
    func test_ambiguous_server_capture_error_returns_success_when_refreshed_intent_confirms_capture() throws {
        // Given
        let clientSecret = "pi_client_secret"
        let intentID = "pi_123"
        let intent = PaymentIntent.fake().copy(id: intentID,
                                               status: .requiresCapture,
                                               clientSecret: clientSecret,
                                               metadata: [PaymentIntent.MetadataKeys.orderID: String(defaultOrderID)])
        let error = ServerSidePaymentCaptureError.paymentGateway(
            error: .orderPaymentCaptureError(message: "Server-side capture failed")
        )
        mockFailedCardPresentPaymentActions(intent: intent, error: error)

        var retrievedClientSecret: String?
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case let .retrievePaymentIntent(clientSecret, completion) = action else { return }
            retrievedClientSecret = clientSecret
            completion(.success(intent.copy(status: .succeeded)))
        }

        // When
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan,
                                        channel: .storeManagement,
                                        onFailure: { _ in },
                                        onCancel: {},
                                        onPaymentCompletion: { promise(()) },
                                        onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertEqual(retrievedClientSecret, clientSecret)
        XCTAssertTrue(mockAnalyticsTracker.didCallTrackSuccessfulPayment)
    }

    func test_ambiguous_server_capture_error_does_not_return_success_when_refreshed_intent_requires_capture() throws {
        // Given
        let intent = ambiguousCapturePaymentIntent()
        let error = ServerSidePaymentCaptureError.paymentGateway(
            error: .orderPaymentCaptureError(message: "Server-side capture failed")
        )
        mockFailedCardPresentPaymentActions(intent: intent, error: error)
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case let .retrievePaymentIntent(_, completion) = action else { return }
            completion(.success(intent.copy(status: .requiresCapture)))
        }

        // When
        let _: CardPresentModalNonRetryableErrorWithoutEmail = waitFor { promise in
            self.alertsPresenter.onPresentCalled = { viewModel in
                guard let errorAlert = viewModel as? CardPresentModalNonRetryableErrorWithoutEmail else { return }
                promise(errorAlert)
            }
            self.useCase.collectPayment(using: .bluetoothScan,
                                        channel: .storeManagement,
                                        onFailure: { _ in },
                                        onCancel: {},
                                        onPaymentCompletion: { XCTFail("Payment should not complete") },
                                        onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }
    }

    func test_ambiguous_server_capture_error_does_not_return_success_for_a_different_payment_intent() throws {
        // Given
        let intent = ambiguousCapturePaymentIntent()
        let error = ServerSidePaymentCaptureError.paymentGateway(
            error: .orderPaymentCaptureError(message: "Server-side capture failed")
        )
        mockFailedCardPresentPaymentActions(intent: intent, error: error)
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case let .retrievePaymentIntent(_, completion) = action else { return }
            completion(.success(intent.copy(id: "pi_different", status: .succeeded)))
        }

        // When
        let _: CardPresentModalNonRetryableErrorWithoutEmail = waitFor { promise in
            self.alertsPresenter.onPresentCalled = { viewModel in
                guard let errorAlert = viewModel as? CardPresentModalNonRetryableErrorWithoutEmail else { return }
                promise(errorAlert)
            }
            self.useCase.collectPayment(using: .bluetoothScan,
                                        channel: .storeManagement,
                                        onFailure: { _ in },
                                        onCancel: {},
                                        onPaymentCompletion: { XCTFail("Payment should not complete") },
                                        onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }
    }

    func test_post_confirmation_error_returns_receipt_capable_success_from_refreshed_intent() throws {
        // Given
        let intent = ambiguousCapturePaymentIntent().copy(
            amount: 150,
            currency: "usd",
            collectedPaymentMethod: .cardPresent(details: .fake())
        )
        let refreshedIntent = intent.copy(status: .succeeded)
        let error = CardReaderServiceError.paymentCapture()
        mockFailedCardPresentPaymentActions(intent: intent, error: error)
        receiptEligibilityUseCase.isEligibleForBackendReceipts = true
        var didRetrieveIntent = false
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            guard case let .retrievePaymentIntent(_, completion) = action else { return }
            didRetrieveIntent = true
            completion(.success(refreshedIntent))
        }

        // When
        let success: CardPresentModalSuccessWithoutEmail = waitFor { promise in
            self.alertsPresenter.onPresentCalled = { viewModel in
                guard let success = viewModel as? CardPresentModalSuccessWithoutEmail else { return }
                promise(success)
            }
            self.useCase.collectPayment(using: .bluetoothScan,
                                        channel: .storeManagement,
                                        onFailure: { _ in },
                                        onCancel: {},
                                        onPaymentCompletion: {},
                                        onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertTrue(didRetrieveIntent)
        XCTAssertNotNil(success.primaryButtonTitle)
        XCTAssertNotNil(refreshedIntent.receiptParameters())
    }

    func test_collectPayment_with_below_minimum_amount_results_in_failure_and_tracks_collectPaymentFailed_event() throws {
        // Given
        let order = Order.fake().copy(total: "0.49")
        let useCase = CollectOrderPaymentUseCase<TapToPayCardReaderPaymentAlertsProvider,
                                                    BluetoothCardReaderPaymentAlertsProvider,
                                                    MockCardPresentPaymentAlertsPresenter>(
            siteID: 122,
            order: order,
            formattedAmount: "0.49",
            rootViewController: MockViewControllerPresenting(),
            configuration: Mocks.configuration,
            stores: stores,
            paymentOrchestrator: mockPaymentOrchestrator,
            alertsPresenter: alertsPresenter,
            tapToPayAlertsProvider: TapToPayCardReaderPaymentAlertsProvider(),
            bluetoothAlertsProvider: BluetoothCardReaderPaymentAlertsProvider(transactionType: .collectPayment),
            preflightController: mockPreflightController,
            analyticsTracker: mockAnalyticsTracker)

        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .retrieveOrderRemotely(_, _, let completion):
                completion(.success(order))
            default:
                break
            }
        }

        // When
        let errorAlert: CardPresentModalNonRetryableErrorWithoutEmail = waitFor { [weak self] promise in
            guard let self else { return }
            self.alertsPresenter.onPresentCalled = { viewModel in
                guard let viewModel = viewModel as? CardPresentModalNonRetryableErrorWithoutEmail else {
                    return
                }
                promise(viewModel)
            }

            useCase.collectPayment(
                using: .bluetoothScan,
                channel: .storeManagement,
                onFailure: { _ in },
                onCancel: {},
                onPaymentCompletion: {},
                onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }
        errorAlert.didTapPrimaryButton(in: nil)

        // Then
        XCTAssert(mockAnalyticsTracker.didCallTrackPaymentFailure)
        let receivedError = try XCTUnwrap(mockAnalyticsTracker.spyTrackPaymentFailureError as? CollectOrderPaymentUseCaseNotValidAmountError)
        assertEqual(CollectOrderPaymentUseCaseNotValidAmountError.belowMinimumAmount(amount: "$0.50"), receivedError)
    }

    func test_dismissing_terminal_payment_preparation_error_cancels_active_payment() throws {
        // Given
        let error = ServerSidePaymentCaptureError.terminalPaymentPreparation(
            error: .orderPaymentCaptureError(message: "Terminal payment preparation failed"))
        var onFailure: ((Error) -> Void)?
        let errorAlert = presentErrorAlert(for: error,
                                           as: CardPresentModalErrorWithoutEmail.self,
                                           onFailure: { onFailure?($0) })

        // When
        let _: Error = waitFor { promise in
            onFailure = { promise($0) }
            errorAlert.didTapSecondaryButton(in: ImmediateDismissViewController())
        }

        // Then
        XCTAssertTrue(mockPaymentOrchestrator.spyDidCallCancelPayment)
    }

    func test_dismissing_payment_capture_error_cancels_active_payment() throws {
        // Given
        let error = CardReaderServiceError.paymentCapture(underlyingError: .internalServiceError)
        var onFailure: ((Error) -> Void)?
        let errorAlert = presentErrorAlert(for: error,
                                           as: CardPresentModalErrorWithoutEmail.self,
                                           onFailure: { onFailure?($0) })

        // When
        let _: Error = waitFor { promise in
            onFailure = { promise($0) }
            errorAlert.didTapSecondaryButton(in: ImmediateDismissViewController())
        }

        // Then
        XCTAssertTrue(mockPaymentOrchestrator.spyDidCallCancelPayment)
    }

    func test_dismissing_payment_collection_timeout_error_does_not_cancel_active_payment() throws {
        // Given
        let error = CardReaderServiceError.paymentMethodCollection(underlyingError: .paymentMethodCollectionTimedOut)
        var onFailure: ((Error) -> Void)?
        let errorAlert = presentErrorAlert(for: error,
                                           as: CardPresentModalNonRetryableErrorWithoutEmail.self,
                                           onFailure: { onFailure?($0) })

        // When
        let _: Error = waitFor { promise in
            onFailure = { promise($0) }
            errorAlert.didTapPrimaryButton(in: nil)
        }

        // Then
        XCTAssertFalse(mockPaymentOrchestrator.spyDidCallCancelPayment)
    }

    func test_dismissing_processing_in_progress_retry_error_does_not_cancel_active_payment() throws {
        // Given
        let error = CardReaderServiceError.retryNotPossibleProcessingInProgress
        var onFailure: ((Error) -> Void)?
        let errorAlert = presentErrorAlert(for: error,
                                           as: CardPresentModalNonRetryableErrorWithoutEmail.self,
                                           onFailure: { onFailure?($0) })

        // When
        let _: Error = waitFor { promise in
            onFailure = { promise($0) }
            errorAlert.didTapPrimaryButton(in: nil)
        }

        // Then
        XCTAssertFalse(mockPaymentOrchestrator.spyDidCallCancelPayment)
    }

    func test_dismissing_server_capture_error_does_not_cancel_active_payment() throws {
        // Given
        let error = ServerSidePaymentCaptureError.paymentGateway(
            error: .orderPaymentCaptureError(message: "Server-side capture failed"))
        var onFailure: ((Error) -> Void)?
        let errorAlert = presentErrorAlert(for: error,
                                           as: CardPresentModalNonRetryableErrorWithoutEmail.self,
                                           onFailure: { onFailure?($0) })

        // When
        let _: Error = waitFor { promise in
            onFailure = { promise($0) }
            errorAlert.didTapPrimaryButton(in: nil)
        }

        // Then
        XCTAssertFalse(mockPaymentOrchestrator.spyDidCallCancelPayment)
    }

    func test_collectPayment_with_interac_dispatches_markOrderAsPaidLocally_after_successful_client_side_capture() throws {
        // Given
        let interacPaymentMethod = PaymentMethod.interacPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: interacPaymentMethod)])
        mockSuccessfulCardPresentPaymentActions(intent: intent,
                                                capturedPaymentData: CardPresentCapturedPaymentData(paymentMethod: interacPaymentMethod,
                                                                                                    receiptParameters: .fake()))
        var markOrderAsPaidLocallyAction: (siteID: Int64, orderID: Int64)?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .retrieveOrderRemotely(_, _, let completion):
                completion(.success(Order.fake().copy(siteID: self.defaultSiteID, orderID: self.defaultOrderID, total: "1.5")))
            case .markOrderAsPaidLocally(let siteID, let orderID, _, _):
                markOrderAsPaidLocallyAction = (siteID: siteID, orderID: orderID)
            default:
                break
            }
        }

        // When
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, channel: .storeManagement, onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {
                promise(())
            }, onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        let action = try XCTUnwrap(markOrderAsPaidLocallyAction)
        XCTAssertEqual(action.siteID, defaultSiteID)
        XCTAssertEqual(action.orderID, defaultOrderID)
    }

    func test_collectPayment_with_noninterac_does_not_dispatch_markOrderAsPaidLocally_after_successful_client_side_capture() throws {
        // Given
        let cardPresentPaymentMethod = PaymentMethod.cardPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: cardPresentPaymentMethod)])
        mockSuccessfulCardPresentPaymentActions(intent: intent,
                                                capturedPaymentData: CardPresentCapturedPaymentData(paymentMethod: cardPresentPaymentMethod,
                                                                                                    receiptParameters: .fake()))
        var markOrderAsPaidLocallyAction: (siteID: Int64, orderID: Int64)?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .retrieveOrderRemotely(_, _, let completion):
                completion(.success(Order.fake().copy(siteID: self.defaultSiteID, orderID: self.defaultOrderID, total: "1.5")))
            case .markOrderAsPaidLocally(let siteID, let orderID, _, _):
                markOrderAsPaidLocallyAction = (siteID: siteID, orderID: orderID)
            default:
                break
            }
        }

        // When
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, channel: .storeManagement, onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {
                promise(())
            }, onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertNil(markOrderAsPaidLocallyAction)
    }

    func test_collectPayment_payment_processor_error_with_customer_then_modal_presented_with_email() throws {
        // Given we have an order with a customer
        let email = "test@test.com"
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5", billingAddress: Address.fake().copy(email: email))

        setUpUseCase(order: order)
        let interacPaymentMethod = PaymentMethod.interacPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: interacPaymentMethod)])
        let error = CardReaderServiceError.paymentCapture(
            underlyingError: .paymentDeclinedByPaymentProcessorAPI(declineReason: .insufficientFunds)
        )
        mockFailedCardPresentPaymentActions(intent: intent,
                                            error: error)
        receiptEligibilityUseCase.isEligibleForFailedPaymentEmailReceipts = true

        // When we make a payment thar results in payment processor error
        waitFor { promise in
            self.alertsPresenter.onPresentCalled = { viewModel in
                if viewModel is CardPresentModalErrorEmailSent {
                    promise(())
                }
            }
            self.useCase.collectPayment(using: .bluetoothScan,
                                        channel: .storeManagement,
                                        onFailure: { _ in },
                                        onCancel: {},
                                        onPaymentCompletion: {},
                                        onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then we should present a modal with the email
        let lastAlert = alertsPresenter.spyPresentedAlertViewModels.last as? CardPresentModalErrorEmailSent
        XCTAssert(lastAlert?.bottomAttributedSubtitle?.string.contains(email) == true)
    }

    func test_collectPayment_card_reader_error_with_customer_then_modal_presented_without_email() throws {
        // Given we have an order with a customer
        let email = "test@test.com"
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5", billingAddress: Address.fake().copy(email: email))

        setUpUseCase(order: order)
        let interacPaymentMethod = PaymentMethod.interacPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: interacPaymentMethod)])
        let error = CardReaderServiceError.disconnection(underlyingError: .bluetoothDisconnected)
        mockFailedCardPresentPaymentActions(intent: intent,
                                            error: error)
        receiptEligibilityUseCase.isEligibleForFailedPaymentEmailReceipts = true

        // When we make a payment that results in card reader disconnection
        waitFor { promise in
            self.alertsPresenter.onPresentCalled = { viewModel in
                if viewModel is CardPresentModalErrorWithoutEmail {
                    promise(())
                }
            }
            self.useCase.collectPayment(using: .bluetoothScan,
                                        channel: .storeManagement,
                                        onFailure: { _ in },
                                        onCancel: {},
                                        onPaymentCompletion: {},
                                        onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then we should present a default modal without the email
        let lastAlert = alertsPresenter.spyPresentedAlertViewModels.last as? CardPresentModalErrorWithoutEmail
        XCTAssertNotNil(lastAlert)
    }

    func test_collectPayment_payment_error_without_customer_then_default_modal_presented() throws {
        // Given we have an order withour a customer email
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5", billingAddress: Address.fake())

        setUpUseCase(order: order)
        let interacPaymentMethod = PaymentMethod.interacPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: interacPaymentMethod)])
        let error = CardReaderServiceError.paymentCapture(
            underlyingError: .paymentDeclinedByPaymentProcessorAPI(declineReason: .insufficientFunds)
        )
        mockFailedCardPresentPaymentActions(intent: intent,
                                            error: error)
        receiptEligibilityUseCase.isEligibleForFailedPaymentEmailReceipts = true

        // When we make a payment thar results in card reader disconnection
        waitFor { promise in
            self.alertsPresenter.onPresentCalled = { viewModel in
                if viewModel is CardPresentModalError {
                    promise(())
                }
            }
            self.useCase.collectPayment(using: .bluetoothScan,
                                        channel: .storeManagement,
                                        onFailure: { _ in },
                                        onCancel: {},
                                        onPaymentCompletion: {},
                                        onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then we should present a default modal without the email
        let lastAlert = alertsPresenter.spyPresentedAlertViewModels.last as? CardPresentModalError
        XCTAssertNotNil(lastAlert)
    }

    func test_collect_payment_when_preflight_connects_tap_to_pay_then_passes_connected_reader_type_to_orchestrator() async {
        // Given
        let reader = MockCardReader.tapToPay()

        // When
        useCase.collectPayment(using: .bluetoothScan,
                               channel: .storeManagement,
                               onFailure: { _ in },
                               onCancel: {},
                               onPaymentCompletion: {},
                               onCompleted: {})
        await waitForPaymentCollection {
            mockPreflightController.completeConnection(reader: reader, gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertEqual(mockPaymentOrchestrator.spyCollectPaymentReaderType, .tapToPay)
    }

    func test_collect_payment_when_preflight_connects_external_reader_then_passes_connected_reader_type_to_orchestrator() async {
        // Given
        let reader = MockCardReader.wisePad3()

        // When
        useCase.collectPayment(using: .tapToPay,
                               channel: .storeManagement,
                               onFailure: { _ in },
                               onCancel: {},
                               onPaymentCompletion: {},
                               onCompleted: {})
        await waitForPaymentCollection {
            mockPreflightController.completeConnection(reader: reader, gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertEqual(mockPaymentOrchestrator.spyCollectPaymentReaderType, .wisepad3)
    }

    func test_collect_payment_when_tap_to_pay_payment_restarts_then_preserves_connected_reader_type() async throws {
        // Given
        var collectedReaderTypes: [CardReaderType] = []
        mockPaymentOrchestrator.mockCollectPaymentHandler = { [weak self] _, _, _, _, _, _, onCompletion in
            guard let self, let readerType = self.mockPaymentOrchestrator.spyCollectPaymentReaderType else { return }
            collectedReaderTypes.append(readerType)
            if collectedReaderTypes.count == 1 {
                onCompletion(.failure(CollectOrderPaymentUseCaseError.paymentGatewayNotFound))
            }
        }
        useCase.collectPayment(using: .tapToPay,
                               channel: .storeManagement,
                               onFailure: { _ in },
                               onCancel: {},
                               onPaymentCompletion: {},
                               onCompleted: {})
        await waitForPaymentCollection {
            mockPreflightController.completeConnection(reader: MockCardReader.tapToPay(), gatewayID: Mocks.paymentGatewayAccount)
        }
        let errorAlert = try XCTUnwrap(alertsPresenter.spyPresentedAlertViewModels.last as? CardPresentModalErrorWithoutEmail)

        // When
        await waitForPaymentCollection {
            errorAlert.didTapPrimaryButton(in: nil)
        }

        // Then
        XCTAssertEqual(collectedReaderTypes, [.tapToPay, .tapToPay])
    }

    func test_collectPayment_channel_is_passed_to_payment_capture_orchestrator() async throws {
        // When
        useCase.collectPayment(using: .bluetoothScan,
                               channel: .pos,
                               onFailure: { _ in },
                               onCancel: {},
                               onPaymentCompletion: {},
                               onCompleted: {})
        await waitForPaymentCollection {
            mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertEqual(mockPaymentOrchestrator.spyChannel, .pos)
    }

    func test_collectPayment_configured_country_is_passed_to_payment_capture_orchestrator() async throws {
        // When
        useCase.collectPayment(using: .bluetoothScan,
                               channel: .storeManagement,
                               onFailure: { _ in },
                               onCancel: {},
                               onPaymentCompletion: {},
                               onCompleted: {})
        await waitForPaymentCollection {
            mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertEqual(mockPaymentOrchestrator.spyCollectPaymentCountryCode, .US)
    }

    func test_completion_called_after_alert_presentation() throws {
        let paymentMethod = PaymentMethod.cardPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: paymentMethod)])
        let capturedPaymentData = CardPresentCapturedPaymentData(paymentMethod: paymentMethod, receiptParameters: .fake())
        mockSuccessfulCardPresentPaymentActions(intent: intent, capturedPaymentData: capturedPaymentData)
        enum Event {
            case alertPresented
            case paymentCompletion
        }
        var eventOrder: [Event] = []

        // Track when receipt alert is presented
        alertsPresenter.onPresentCalled = { viewModel in
            if viewModel is CardPresentModalSuccessWithoutEmail ||
               viewModel is CardPresentModalSuccessEmailSent {
                eventOrder.append(.alertPresented)
            }
        }

        // When payment succeeds
        waitFor { promise in
            self.useCase.collectPayment(
                using: .bluetoothScan,
                channel: .storeManagement,
                onFailure: { _ in },
                onCancel: {},
                onPaymentCompletion: {
                    eventOrder.append(.paymentCompletion)
                    promise(())
                },
                onCompleted: {}
            )
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then ensure payment completion happens after alert presentation to avoid CollectOrderPaymentUseCase deinit before alert presentation
        XCTAssertEqual(eventOrder, [.alertPresented, .paymentCompletion])
    }

    func test_collectPayment_when_backend_receipt_is_not_eligible_then_completes_without_receipt_alert() throws {
        // Given
        receiptEligibilityUseCase.isEligibleForBackendReceipts = false
        let paymentMethod = PaymentMethod.cardPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: paymentMethod)])
        let capturedPaymentData = CardPresentCapturedPaymentData(paymentMethod: paymentMethod, receiptParameters: .fake())
        mockSuccessfulCardPresentPaymentActions(intent: intent, capturedPaymentData: capturedPaymentData)

        var didCompletePayment = false
        var didCompleteFlow = false

        // When
        waitFor { promise in
            self.useCase.collectPayment(
                using: .bluetoothScan,
                channel: .storeManagement,
                onFailure: { _ in },
                onCancel: {},
                onPaymentCompletion: {
                    didCompletePayment = true
                    promise(())
                },
                onCompleted: {
                    didCompleteFlow = true
                }
            )
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertTrue(didCompletePayment)
        XCTAssertTrue(didCompleteFlow)
        XCTAssertFalse(alertsPresenter.spyPresentedAlertViewModels.contains { viewModel in
            viewModel is CardPresentModalSuccessWithoutEmail || viewModel is CardPresentModalSuccessEmailSent
        })
    }

    func test_collectPayment_succeeds_when_order_total_precision_differs_between_initial_and_retrieved_order() throws {
        // Given an order with 2 decimal place precision
        let initialOrder = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "22.56")

        // And the retrieved order has 8 decimal place precision (same value, different formatting)
        let retrievedOrder = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "22.56000000")

        setUpUseCase(order: initialOrder)

        // Mock the order retrieval to return the 8dp version
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .retrieveOrderRemotely(_, _, let completion):
                completion(.success(retrievedOrder))
            default:
                break
            }
        }

        let paymentMethod = PaymentMethod.cardPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: paymentMethod)])
        let capturedPaymentData = CardPresentCapturedPaymentData(paymentMethod: paymentMethod, receiptParameters: .fake())
        mockSuccessfulCardPresentPaymentActions(intent: intent, capturedPaymentData: capturedPaymentData)

        // When collecting payment
        var paymentCompleted = false
        var paymentFailed = false

        waitFor { promise in
            self.useCase.collectPayment(
                using: .bluetoothScan,
                channel: .storeManagement,
                onFailure: { error in
                    paymentFailed = true
                    // This should not happen with the decimal comparison fix
                    XCTFail("Payment should not fail due to precision mismatch. Error: \(error)")
                    promise(())
                },
                onCancel: {
                    XCTFail("Payment should not be canceled")
                    promise(())
                },
                onPaymentCompletion: {
                    paymentCompleted = true
                    promise(())
                },
                onCompleted: {}
            )
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then payment should succeed (with decimal comparison, "22.56" equals "22.56000000")
        XCTAssertTrue(paymentCompleted)
        XCTAssertFalse(paymentFailed)
    }
}

private extension CollectOrderPaymentUseCaseTests {
    func waitForPaymentCollection(_ connect: () -> Void) async {
        let collected = expectation(description: "Payment collection started after order validation")
        let handler = mockPaymentOrchestrator.mockCollectPaymentHandler
        defer { mockPaymentOrchestrator.mockCollectPaymentHandler = handler }
        mockPaymentOrchestrator.mockCollectPaymentHandler = { preparing, waiting, processing, inserted, display, confirmed, completion in
            handler?(preparing, waiting, processing, inserted, display, confirmed, completion)
            collected.fulfill()
        }
        connect()
        await fulfillment(of: [collected], timeout: Constants.expectationTimeout)
    }

    func assertInteracConfirmationDuringCancellation(newerPOSConfirmation: Bool) async throws {
        // Given
        let analytics = MockPOSAnalytics()
        var milliseconds = 0
        let tracker = POSCollectOrderPaymentAnalyticsAdaptor(analytics: analytics, monotonicMilliseconds: { milliseconds })
        tracker.trackCheckoutTapped()
        let pending = try await beginCancellationWithHeldCallback(analyticsTracker: tracker, channel: .pos)
        if newerPOSConfirmation {
            milliseconds = 200
            tracker.trackProcessingCompletion(intent: .fake(), recordPaymentConfirmation: true)
        }
        // When
        milliseconds = 250
        pending.confirm(PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: .interacPresent(details: .fake()))]))
        // Then
        XCTAssertEqual(analytics.events.filter { $0.eventName == "card_interac_collect_payment_success" }.count, 1)
        // When
        pending.finishCancellation(.failure(TestError.cancellationFailed))
        milliseconds = 300
        tracker.trackPaymentFailure(with: TestError.cancellationFailed)
        // Then
        XCTAssertEqual(analytics.events.last?.properties["pos_time_since_payment_confirmed_ms"] as? Int,
                       newerPOSConfirmation ? 100 : nil)
    }

    func beginCancellationWithHeldCallback(analyticsTracker: CollectOrderPaymentAnalyticsTracking,
                                           channel: PaymentChannel) async throws -> (confirm: (PaymentIntent) -> Void,
                                                                              finishCancellation: (Result<Void, Error>) -> Void) {
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
        setUpUseCase(order: order, analyticsTracker: analyticsTracker)
        mockPaymentOrchestrator.mockCollectPaymentHandler = { _, onWaitingForInput, _, _, _, _, _ in
            onWaitingForInput(.tap)
        }
        var finishCancellation: ((Result<Void, Error>) -> Void)?
        mockPaymentOrchestrator.mockCancelPaymentHandler = { finishCancellation = $0 }
        useCase.collectPayment(using: .bluetoothScan, channel: channel,
                               onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {}, onCompleted: {})
        await waitForPaymentCollection {
            mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }
        let waitingAlert = try XCTUnwrap(alertsPresenter.spyPresentedAlertViewModels.last)
        waitingAlert.didTapSecondaryButton(in: ImmediateDismissViewController())
        return (try XCTUnwrap(mockPaymentOrchestrator.spyProcessingCompletion), try XCTUnwrap(finishCancellation))
    }

    func ambiguousCapturePaymentIntent() -> PaymentIntent {
        PaymentIntent.fake().copy(id: "pi_123",
                                  status: .requiresCapture,
                                  clientSecret: "pi_client_secret",
                                  metadata: [PaymentIntent.MetadataKeys.orderID: String(defaultOrderID)])
    }

    func presentErrorAlert<Alert: CardPresentPaymentsModalViewModel>(for error: Error,
                                                                     as alertType: Alert.Type,
                                                                     onFailure: @escaping (Error) -> Void) -> Alert {
        let paymentMethod = PaymentMethod.cardPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: paymentMethod)])
        mockFailedCardPresentPaymentActions(intent: intent, error: error)

        return waitFor { promise in
            self.alertsPresenter.onPresentCalled = { viewModel in
                guard let errorAlert = viewModel as? Alert else {
                    return
                }
                promise(errorAlert)
            }
            self.useCase.collectPayment(using: .bluetoothScan,
                                        channel: .storeManagement,
                                        onFailure: onFailure,
                                        onCancel: {},
                                        onPaymentCompletion: {},
                                        onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }
    }

    func mockTerminalPaymentPreparationRoute(isAvailable: Bool) {
        stores.whenReceivingAction(ofType: SettingAction.self) { [defaultSiteID] action in
            switch action {
            case let .retrieveSiteAPI(siteID, _, completion):
                XCTAssertEqual(siteID, defaultSiteID)
                completion(.success(SiteAPI(siteID: siteID,
                                            namespaces: [],
                                            applicationPasswordAvailable: false,
                                            routes: isAvailable ? [Mocks.prepareTerminalPaymentRoute] : [])))
            default:
                XCTFail("Unexpected setting action: \(action)")
            }
        }
    }

    func mockUnexpectedTerminalPaymentPreparationRouteCheck() {
        stores.whenReceivingAction(ofType: SettingAction.self) { action in
            switch action {
            case let .retrieveSiteAPI(siteID, _, completion):
                XCTFail("AU terminal payment preparation should not depend on the site route list.")
                completion(.success(SiteAPI(siteID: siteID,
                                            namespaces: [],
                                            applicationPasswordAvailable: false,
                                            routes: [])))
            default:
                XCTFail("Unexpected setting action: \(action)")
            }
        }
    }

    func mockSuccessfulCardPresentPaymentActions(intent: PaymentIntent, capturedPaymentData: CardPresentCapturedPaymentData) {
        mockPaymentOrchestrator.mockCollectPaymentHandler = { _,
                                                              _,
                                                              _,
                                                              _,
                                                              _,
                                                              onProcessingCompletion,
                                                              onCompletion in
            onProcessingCompletion(intent)
            onCompletion(.success(capturedPaymentData))
        }
    }

    func mockFailedCardPresentPaymentActions(intent: PaymentIntent, error: any Error) {
        mockPaymentOrchestrator.mockCollectPaymentHandler = { _,
                                                              _,
                                                              _,
                                                              _,
                                                              _,
                                                              onProcessingCompletion,
                                                              onCompletion in
            onProcessingCompletion(intent)
            onCompletion(.failure(error))
        }
    }
}

private extension CollectOrderPaymentUseCaseTests {
    enum TestError: Error {
        case cancellationFailed
    }

    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: .US)
        static let cardReaderModel: String = "WISEPAD_3"
        static let paymentGatewayAccount: String = "woocommerce-payments"
        static let prepareTerminalPaymentRoute = "/wc/v3/payments/orders/(?P<order_id>\\w+)/prepare_terminal_payment"
    }
}

private final class ImmediateDismissViewController: UIViewController {
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        completion?()
    }
}
