import Codegen
import Combine
import TestKit
import XCTest
import Yosemite
@testable import WooCommerce

final class CollectOrderPaymentUseCaseTests: XCTestCase {
    private let defaultSiteID: Int64 = 122
    private let defaultOrderID: Int64 = 322

    private var stores: MockStoresManager!
    private var alertsPresenter: MockCardPresentPaymentAlertsPresenter!
    private var onboardingPresenter: MockCardPresentPaymentsOnboardingPresenter!
    private var mockPreflightController: MockCardPresentPaymentPreflightController!
    private var mockAnalyticsTracker: MockCollectOrderPaymentAnalyticsTracker!
    private var useCase: CollectOrderPaymentUseCase!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        stores.reset()
        mockAnalyticsTracker = MockCollectOrderPaymentAnalyticsTracker()
        onboardingPresenter = MockCardPresentPaymentsOnboardingPresenter()

        alertsPresenter = MockCardPresentPaymentAlertsPresenter()
        mockPreflightController = MockCardPresentPaymentPreflightController()
        useCase = CollectOrderPaymentUseCase(siteID: defaultSiteID,
                                             order: .fake().copy(siteID: defaultSiteID, orderID: defaultOrderID, total: "1.5"),
                                             formattedAmount: "1.5",
                                             rootViewController: .init(),
                                             onboardingPresenter: onboardingPresenter,
                                             configuration: Mocks.configuration,
                                             stores: stores,
                                             paymentCaptureCelebration: MockPaymentCaptureCelebration(), alertsPresenter: alertsPresenter,
                                             preflightController: mockPreflightController,
                                             analyticsTracker: mockAnalyticsTracker)
    }

    func test_cancelling_reader_connection_triggers_onCancel_and_tracks_collectPaymentCanceled_event() throws {
        // Given
        assertEmpty(stores.receivedActions)

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

    func test_collectPayment_processing_completion_tracks_payment_success_event() throws {
        // Given
        let interacPaymentMethod = PaymentMethod.interacPresent(details: .fake())
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: interacPaymentMethod)])
        mockSuccessfulCardPresentPaymentActions(intent: intent)

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
        let useCase = CollectOrderPaymentUseCase(siteID: 122,
                                                 order: .fake().copy(total: "0.49"),
                                                 formattedAmount: "0.49",
                                                 rootViewController: .init(),
                                                 onboardingPresenter: onboardingPresenter,
                                                 configuration: Mocks.configuration,
                                                 stores: stores,
                                                 paymentCaptureCelebration: MockPaymentCaptureCelebration(),
                                                 alertsPresenter: alertsPresenter,
                                                 analyticsTracker: mockAnalyticsTracker)

        // When
        waitFor { [weak self] promise in
            useCase.collectPayment(
                using: .bluetoothScan,
                onFailure: { _ in
                    promise(())
                },
                onCancel: {},
                onPaymentCompletion: {},
                onCompleted: {})
            let errorAlert = self?.alertsPresenter.spyPresentedAlertViewModels.last(where: { $0 is CardPresentModalNonRetryableError })
            errorAlert?.didTapPrimaryButton(in: nil)
        }

        // Then
        XCTAssert(mockAnalyticsTracker.didCallTrackPaymentFailure)
        let receivedError = try XCTUnwrap(mockAnalyticsTracker.spyTrackPaymentFailureError as? CollectOrderPaymentUseCase.NotValidAmountError)
        assertEqual(CollectOrderPaymentUseCase.NotValidAmountError.belowMinimumAmount(amount: "$0.50"), receivedError)
    }

    func test_collectPayment_with_interac_dispatches_markOrderAsPaidLocally_after_successful_client_side_capture() throws {
        // Given
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: .interacPresent(details: .fake()))])
        mockSuccessfulCardPresentPaymentActions(intent: intent)
        var markOrderAsPaidLocallyAction: (siteID: Int64, orderID: Int64)?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            if case let .markOrderAsPaidLocally(siteID, orderID, _, _) = action {
                markOrderAsPaidLocallyAction = (siteID: siteID, orderID: orderID)
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
        let intent = PaymentIntent.fake().copy(charges: [.fake().copy(paymentMethod: .cardPresent(details: .fake()))])
        mockSuccessfulCardPresentPaymentActions(intent: intent)
        var markOrderAsPaidLocallyAction: (siteID: Int64, orderID: Int64)?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            if case let .markOrderAsPaidLocally(siteID, orderID, _, _) = action {
                markOrderAsPaidLocallyAction = (siteID: siteID, orderID: orderID)
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
    func mockCardPresentPaymentActions() {
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .publishCardReaderConnections(completion) = action {
                completion(Just<[CardReader]>([MockCardReader.wisePad3()]).eraseToAnyPublisher())
            } else if case let .observeConnectedReaders(completion) = action {
                completion([MockCardReader.wisePad3()])
            } else if case let .cancelPayment(completion) = action {
                completion?(.success(()))
            } else if case let .collectPayment(_, _, _, onCardReaderMessage, _, _) = action {
                onCardReaderMessage(.waitingForInput([]))
            }
        }

        stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case .synchronizeSystemPlugins(_, let completion):
                completion(.success([]))
            default:
                break
            }
        }
    }

    func mockSuccessfulCardPresentPaymentActions(intent: PaymentIntent) {
        stores.whenReceivingAction(ofType: CardPresentPaymentAction.self) { action in
            if case let .publishCardReaderConnections(completion) = action {
                completion(Just<[CardReader]>([MockCardReader.wisePad3()]).eraseToAnyPublisher())
            } else if case let .observeConnectedReaders(completion) = action {
                completion([MockCardReader.wisePad3()])
            } else if case let .collectPayment(_, _, _, _, onProcessingCompletion, onCompletion) = action {
                onProcessingCompletion(intent)
                onCompletion(.success(intent))
            }
        }
    }
}

private extension CollectOrderPaymentUseCaseTests {
    enum Mocks {
        static let configuration = CardPresentPaymentsConfiguration(country: "US")
        static let cardReaderModel: String = "WISEPAD_3"
        static let paymentGatewayAccount: String = "woocommerce-payments"
    }
}
