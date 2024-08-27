import Codegen
import Combine
import TestKit
import XCTest
import Yosemite
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
    private var useCase: CollectOrderPaymentUseCase<BuiltInCardReaderPaymentAlertsProvider,
                                                        BluetoothCardReaderPaymentAlertsProvider,
                                                        MockCardPresentPaymentAlertsPresenter>!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.reset()
        mockAnalyticsTracker = MockCollectOrderPaymentAnalyticsTracker()
        mockPaymentOrchestrator = MockPaymentCaptureOrchestrator()
        alertsPresenter = MockCardPresentPaymentAlertsPresenter()
        mockPreflightController = MockCardPresentPaymentPreflightController()

        let order = Order.fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5")
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
                                             configuration: Mocks.configuration,
                                             stores: stores,
                                             paymentOrchestrator: mockPaymentOrchestrator,
                                             alertsPresenter: alertsPresenter,
                                             tapToPayAlertsProvider: BuiltInCardReaderPaymentAlertsProvider(),
                                             bluetoothAlertsProvider: BluetoothCardReaderPaymentAlertsProvider(transactionType: .collectPayment),
                                             preflightController: mockPreflightController,
                                             analyticsTracker: mockAnalyticsTracker)
    }

    func test_cancelling_reader_connection_triggers_onCancel_and_tracks_collectPaymentCanceled_event() throws {
        // Given

        // When
        let _: Void = waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, onFailure: { _ in }, onCancel: {
                promise(())
            }, onPaymentCompletion: {}, onCompleted: {})
            self.mockPreflightController.cancelConnection(readerModel: Mocks.cardReaderModel, gatewayID: Mocks.paymentGatewayAccount, source: .foundReader)
        }

        // Then
        XCTAssertTrue(mockAnalyticsTracker.didCallTrackPaymentCancelation)
        assertEqual(.foundReader, mockAnalyticsTracker.spyPaymentCancelationSource)
    }

    func test_collectPayment_processing_completion_tracks_payment_success_event() async throws {
        // Given
        let interacPaymentMethod = PaymentMethod.interacPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: interacPaymentMethod)])
        mockSuccessfulCardPresentPaymentActions(intent: intent,
                                                capturedPaymentData: CardPresentCapturedPaymentData(paymentMethod: interacPaymentMethod,
                                                                                                    receiptParameters: .fake()))

        // When
        waitFor { promise in
            self.useCase.collectPayment(using: .bluetoothScan, onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {
                promise(())
            }, onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssert(mockAnalyticsTracker.didCallTrackSuccessfulPayment)
        assertEqual(interacPaymentMethod, mockAnalyticsTracker.spyTrackSuccessfulPaymentCapturedPaymentData?.paymentMethod)
    }

    // MARK: - Failure cases
    func test_collectPayment_with_below_minimum_amount_results_in_failure_and_tracks_collectPaymentFailed_event() throws {
        // Given
        let order = Order.fake().copy(total: "0.49")
        let useCase = CollectOrderPaymentUseCase<BuiltInCardReaderPaymentAlertsProvider,
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
            tapToPayAlertsProvider: BuiltInCardReaderPaymentAlertsProvider(),
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
        let errorAlert: CardPresentModalNonRetryableError = waitFor { [weak self] promise in
            guard let self = self else { return }
            self.alertsPresenter.onPresentCalled = { viewModel in
                guard let viewModel = viewModel as? CardPresentModalNonRetryableError else {
                    return
                }
                promise(viewModel)
            }

            useCase.collectPayment(
                using: .bluetoothScan,
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
            self.useCase.collectPayment(using: .bluetoothScan, onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {
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
            self.useCase.collectPayment(using: .bluetoothScan, onFailure: { _ in }, onCancel: {}, onPaymentCompletion: {
                promise(())
            }, onCompleted: {})
            self.mockPreflightController.completeConnection(reader: MockCardReader.wisePad3(), gatewayID: Mocks.paymentGatewayAccount)
        }

        // Then
        XCTAssertNil(markOrderAsPaidLocallyAction)
    }
}

private extension CollectOrderPaymentUseCaseTests {
    func mockSuccessfulCardPresentPaymentActions(intent: PaymentIntent, capturedPaymentData: CardPresentCapturedPaymentData) {
        mockPaymentOrchestrator.mockCollectPaymentHandler = { onPreparingReader,
                                                              onWaitingForInput,
                                                              onProcessingMessage,
                                                              onDisplayMessage,
                                                              onProcessingCompletion,
                                                              onCompletion in
            onProcessingCompletion(intent)
            onCompletion(.success(capturedPaymentData))
        }
    }
}

private extension CollectOrderPaymentUseCaseTests {
    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: .US)
        static let cardReaderModel: String = "WISEPAD_3"
        static let paymentGatewayAccount: String = "woocommerce-payments"
    }
}
