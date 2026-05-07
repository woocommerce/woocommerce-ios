import Codegen
import Combine
import Networking
import TestKit
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

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.reset()
        mockAnalyticsTracker = MockCollectOrderPaymentAnalyticsTracker()
        mockPaymentOrchestrator = MockPaymentCaptureOrchestrator()
        alertsPresenter = MockCardPresentPaymentAlertsPresenter()
        mockPreflightController = MockCardPresentPaymentPreflightController()
        receiptEligibilityUseCase = MockReceiptEligibilityUseCase()

        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
        setUpUseCase(order: order)
    }

    private func setUpUseCase(order: Order, configuration: CardPresentPaymentsConfiguration = Mocks.configuration) {
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
                                             analyticsTracker: mockAnalyticsTracker,
                                             receiptEligibilityUseCase: receiptEligibilityUseCase)
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

    func test_collectPayment_enables_terminal_payment_preparation_when_flag_is_enabled_and_route_is_available_for_Canada() throws {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .CA)
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
        setUpUseCase(order: order, configuration: configuration)
        mockTerminalPaymentPreparationFeatureFlag(isEnabled: true)
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

    func test_collectPayment_disables_terminal_payment_preparation_when_flag_is_disabled() throws {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .CA)
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
        setUpUseCase(order: order, configuration: configuration)
        mockTerminalPaymentPreparationFeatureFlag(isEnabled: false)

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

    func test_collectPayment_disables_terminal_payment_preparation_when_route_is_not_available_for_Canada() throws {
        // Given
        let configuration = CardPresentPaymentsConfiguration(country: .CA)
        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
        setUpUseCase(order: order, configuration: configuration)
        mockTerminalPaymentPreparationFeatureFlag(isEnabled: true)
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
        mockTerminalPaymentPreparationFeatureFlag(isEnabled: true)
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

    func test_collectPayment_channel_is_passed_to_payment_capture_orchestrator() throws {
        // When
        useCase.collectPayment(using: .bluetoothScan,
                               channel: .pos,
                               onFailure: { _ in },
                               onCancel: {},
                               onPaymentCompletion: {},
                               onCompleted: {})
        mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)

        // Then
        XCTAssertEqual(mockPaymentOrchestrator.spyChannel, .pos)
    }

    func test_collectPayment_configured_country_is_passed_to_payment_capture_orchestrator() throws {
        // When
        useCase.collectPayment(using: .bluetoothScan,
                               channel: .storeManagement,
                               onFailure: { _ in },
                               onCancel: {},
                               onPaymentCompletion: {},
                               onCompleted: {})
        mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)

        // Then
        XCTAssertEqual(mockPaymentOrchestrator.spyCollectPaymentCountryCode, .US)
    }

    func test_completion_called_after_alert_presentation() throws {
        receiptEligibilityUseCase.isEligibleForBackendReceipts = true
        let paymentMethod = PaymentMethod.cardPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: paymentMethod)])
        let capturedPaymentData = CardPresentCapturedPaymentData(paymentMethod: paymentMethod, receiptParameters: .fake())
        mockSuccessfulCardPresentPaymentActions(intent: intent, capturedPaymentData: capturedPaymentData)
        enum Event {
            case receiptEligibilityCheck
            case alertPresented
            case paymentCompletion
        }
        var eventOrder: [Event] = []

        receiptEligibilityUseCase.mockIsEligibleForBackendReceiptsHandler = { completion in
            // Force receiptEligibilityCheck completion delay
            DispatchQueue.main.async {
                eventOrder.append(.receiptEligibilityCheck)
                completion(true)
            }
        }

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
        XCTAssertEqual(eventOrder, [.receiptEligibilityCheck, .alertPresented, .paymentCompletion])
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
    func mockTerminalPaymentPreparationFeatureFlag(isEnabled: Bool) {
        stores.whenReceivingAction(ofType: FeatureFlagAction.self) { action in
            switch action {
            case let .isRemoteFeatureFlagEnabled(featureFlag, defaultValue, _, completion):
                XCTAssertEqual(featureFlag, .inPersonPaymentsTerminalPaymentPreparation)
                XCTAssertFalse(defaultValue)
                completion(isEnabled)
            }
        }
    }

    func mockTerminalPaymentPreparationRoute(isAvailable: Bool) {
        stores.whenReceivingAction(ofType: SettingAction.self) { [defaultSiteID] action in
            switch action {
            case let .retrieveSiteAPI(siteID, completion):
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
            case let .retrieveSiteAPI(siteID, completion):
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
        mockPaymentOrchestrator.mockCollectPaymentHandler = { onPreparingReader,
                                                              onWaitingForInput,
                                                              onProcessingMessage,
                                                              onCardInserted,
                                                              onDisplayMessage,
                                                              onProcessingCompletion,
                                                              onCompletion in
            onProcessingCompletion(intent)
            onCompletion(.success(capturedPaymentData))
        }
    }

    func mockFailedCardPresentPaymentActions(intent: PaymentIntent, error: any Error) {
        mockPaymentOrchestrator.mockCollectPaymentHandler = { onPreparingReader,
                                                              onWaitingForInput,
                                                              onProcessingMessage,
                                                              onCardInserted,
                                                              onDisplayMessage,
                                                              onProcessingCompletion,
                                                              onCompletion in
            onProcessingCompletion(intent)
            onCompletion(.failure(error))
        }
    }
}

private extension CollectOrderPaymentUseCaseTests {
    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: .US)
        static let cardReaderModel: String = "WISEPAD_3"
        static let paymentGatewayAccount: String = "woocommerce-payments"
        static let prepareTerminalPaymentRoute = "/wc/v3/payments/orders/(?P<order_id>\\w+)/prepare_terminal_payment"
    }
}
