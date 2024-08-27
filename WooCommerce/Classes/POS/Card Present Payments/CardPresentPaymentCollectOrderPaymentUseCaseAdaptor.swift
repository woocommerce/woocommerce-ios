import Foundation
import WooFoundation
import Combine
import struct Yosemite.Order
import struct Yosemite.CardPresentPaymentsConfiguration
import protocol Yosemite.StoresManager
import enum Yosemite.CardPresentPaymentAction

final class CardPresentPaymentCollectOrderPaymentUseCaseAdaptor {
    private let currencyFormatter: CurrencyFormatter
    @Published private var latestPaymentEvent: CardPresentPaymentEvent = .idle
    private let stores: StoresManager

    init(currencyFormatter: CurrencyFormatter = .init(currencySettings: ServiceLocator.currencySettings),
         paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never>,
         stores: StoresManager = ServiceLocator.stores) {
        self.currencyFormatter = currencyFormatter
        self.stores = stores
        paymentEventPublisher.assign(to: &$latestPaymentEvent)
    }

    func collectPaymentTask(for order: Order,
                            using connectionMethod: CardReaderConnectionMethod,
                            siteID: Int64,
                            preflightController: CardPresentPaymentPreflightController<
                            CardPresentPaymentBuiltInReaderConnectionAlertsProvider,
                            CardPresentPaymentBluetoothReaderConnectionAlertsProvider,
                            CardPresentPaymentsAlertPresenterAdaptor>,
                            onboardingPresenter: CardPresentPaymentsOnboardingPresenting,
                            configuration: CardPresentPaymentsConfiguration,
                            alertsPresenter: CardPresentPaymentsAlertPresenterAdaptor,
                            paymentEventSubject: any Subject<CardPresentPaymentEvent, Never>) -> Task<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error> {
        return Task {
            guard let formattedAmount = currencyFormatter.formatAmount(order.total, with: order.currency) else {
                throw CardPresentPaymentServiceError.invalidAmount
            }

            let invalidatablePaymentOrchestrator = CardPresentPaymentInvalidatablePaymentOrchestrator()

            let orderPaymentUseCase = CollectOrderPaymentUseCase<CardPresentPaymentsTransactionAlertsProvider,
                                                                 CardPresentPaymentsTransactionAlertsProvider,
                                                                    CardPresentPaymentsAlertPresenterAdaptor>(
                siteID: siteID,
                order: order,
                formattedAmount: formattedAmount,
                rootViewController: NullViewControllerPresenting(),
                configuration: configuration,
                paymentOrchestrator: invalidatablePaymentOrchestrator,
                alertsPresenter: alertsPresenter,
                tapToPayAlertsProvider: CardPresentPaymentsTransactionAlertsProvider(),
                bluetoothAlertsProvider: CardPresentPaymentsTransactionAlertsProvider(),
                preflightController: preflightController)

            return try await withTaskCancellationHandler {
                return try await withCheckedThrowingContinuation { continuation in
                    // The nillableContinuation prevents us accidentally resuming it twice.
                    var nillableContinuation: CheckedContinuation<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error>? = continuation

                    orderPaymentUseCase.collectPayment(
                        using: connectionMethod.discoveryMethod,
                        onFailure: { error in
                            guard let continuation = nillableContinuation else { return }
                            nillableContinuation = nil

                            if let error = error as? CardPaymentErrorProtocol {
                                continuation.resume(throwing: error)
                                // TODO: Some of these errors are retriable with the same payment intent.
                                // This isn't catered for yet. Perhaps those should not be thrown as errors,
                                // but sent to `paymentEventSubject` as events with retry/cancel handlers.
                                // if we do that, we shouldn't nil the continuation until we're definitely calling it,
                                // i.e. in those handlers.
                            } else {
                                continuation.resume(throwing: CardPresentPaymentServiceError.unknownPaymentError(underlyingError: error))
                            }
                        },
                        onCancel: {
                            guard let continuation = nillableContinuation else { return }
                            nillableContinuation = nil
                            paymentEventSubject.send(.idle)
                            continuation.resume(returning: CardPresentPaymentAdaptedCollectOrderPaymentResult.cancellation)
                        },
                        onPaymentCompletion: {
                            guard let continuation = nillableContinuation else { return }
                            nillableContinuation = nil
                            continuation.resume(returning: CardPresentPaymentAdaptedCollectOrderPaymentResult.success)
                        },
                        onCompleted: {
                            // This isn't required for our use case yet.
                            // In the IPP implementation is only called when the receipt is dismissed or discarded
                        }
                    )
                }
            } onCancel: {
                invalidatablePaymentOrchestrator.invalidatePayment()
                switch latestPaymentEvent {
                    case .show(let eventDetails):
                        onCancel(paymentEventDetails: eventDetails, paymentOrchestrator: invalidatablePaymentOrchestrator)
                    case .idle, .showOnboarding:
                        return
                }
            }
        }
    }
}

enum CardPresentPaymentAdaptedCollectOrderPaymentResult {
    case success
    case cancellation
}

private extension CardPresentPaymentCollectOrderPaymentUseCaseAdaptor {
    func onCancel(paymentEventDetails: CardPresentPaymentEventDetails, paymentOrchestrator: PaymentCaptureOrchestrating) {
        switch paymentEventDetails {
            /// Before reader connection
        case .selectSearchType:
            cancelReaderSearch()
        case .scanningForReaders(let endSearch),
                .scanningFailed(_, let endSearch),
                .bluetoothRequired(_, let endSearch),
                .connectingFailed(_, _, let endSearch),
                .connectingFailedNonRetryable(_, let endSearch),
                .connectingFailedUpdatePostalCode(_, let endSearch),
                .connectingFailedChargeReader(_, let endSearch),
                .connectingFailedUpdateAddress(_, _, _, let endSearch),
                .foundReader(_, _, _, let endSearch):
            endSearch()
        case .foundMultipleReaders(_, let selectionHandler):
            selectionHandler(nil)
        case .updateProgress(_, _, let cancelUpdate):
            cancelUpdate?()
        case .updateFailed(_, let cancelUpdate),
                .updateFailedNonRetryable(let cancelUpdate),
                .updateFailedLowBattery(_, let cancelUpdate):
            cancelUpdate()
        case .connectingToReader:
            // We can't cancel an in-progress connection, but we've invalidated the payment orchestrator
            return
            /// Connection already completed, before attempting payment
        case .validatingOrder, .connectionSuccess:
            // No need to cancel at this stage – having invalidated the payment orchestrator is enough
            return
        case .preparingForPayment(cancelPayment: let cancelPayment),
                .tapSwipeOrInsertCard(_, cancelPayment: let cancelPayment),
                .paymentError(_, _, cancelPayment: let cancelPayment),
                .paymentCaptureError(cancelPayment: let cancelPayment):
            cancelPayment()
        case .processing, /// if cancellation fails here, which is likely, we may need a new order. But we can disable going back to make it unlikely.
                .displayReaderMessage,
            /// An alert to notify the merchant that the transaction was cancelled using a button on the reader
                .cancelledOnReader:
            cancelPayment(paymentOrchestrator: paymentOrchestrator)
        case .paymentSuccess(done: let done):
            done()
        }
    }
}

private extension CardPresentPaymentCollectOrderPaymentUseCaseAdaptor {
    func cancelReaderSearch() {
        stores.dispatch(CardPresentPaymentAction.cancelCardReaderDiscovery() { _ in })
    }

    func cancelPayment(paymentOrchestrator: PaymentCaptureOrchestrating) {
        paymentOrchestrator.cancelPayment { _ in }
    }
}
