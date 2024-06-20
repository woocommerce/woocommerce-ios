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

            let orderPaymentUseCase = CollectOrderPaymentUseCase<CardPresentPaymentsTransactionAlertsProvider,
                                                                 CardPresentPaymentsTransactionAlertsProvider,
                                                                    CardPresentPaymentsAlertPresenterAdaptor>(
                siteID: siteID,
                order: order,
                formattedAmount: formattedAmount,
                rootViewController: NullViewControllerPresenting(),
                configuration: configuration,
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
                            // This isn't required for our use case yet.
                        },
                        onCompleted: {
                            guard let continuation = nillableContinuation else { return }
                            nillableContinuation = nil
                            paymentEventSubject.send(.idle)
                            continuation.resume(returning: CardPresentPaymentAdaptedCollectOrderPaymentResult.success)
                        }
                    )
                }
            } onCancel: {
                // TODO: cancel any in-progress discovery, connection, or payment. #12869
                switch latestPaymentEvent {
                    case .show(let eventDetails):
                        onCancel(paymentEventDetails: eventDetails)
                    case .showReaderList:
                        // TODO: to be merged to the case above
                        return
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
    func onCancel(paymentEventDetails: CardPresentPaymentEventDetails) {
        switch paymentEventDetails {
            case .scanningForReaders(let endSearch):
                endSearch()
            case .scanningFailed(let error, let endSearch):
                endSearch()
            case .bluetoothRequired(let error, let endSearch):
                endSearch()
            case .connectingToReader:
                // TODO: cancel connection if possible?
                return
            case .connectingFailed(let error, let retrySearch, let endSearch):
                endSearch()
            case .connectingFailedNonRetryable(let error, let endSearch):
                endSearch()
            case .connectingFailedUpdatePostalCode(let retrySearch, let endSearch):
                endSearch()
            case .connectingFailedChargeReader(let retrySearch, let endSearch):
                endSearch()
            case .connectingFailedUpdateAddress(let wcSettingsAdminURL, let retrySearch, let endSearch):
                endSearch()
            case .foundReader(let name, let connect, let continueSearch, let endSearch):
                endSearch()
            case .updateProgress(let requiredUpdate, let progress, let cancelUpdate):
                // TODO: handle optional case if possible?
                cancelUpdate?()
            case .updateFailed(let tryAgain, let cancelUpdate):
                cancelUpdate()
            case .updateFailedNonRetryable(let cancelUpdate):
                cancelUpdate()
            case .updateFailedLowBattery(let batteryLevel, let cancelUpdate):
                cancelUpdate()
            case .preparingForPayment(cancelPayment: let cancelPayment):
                cancelPayment()
            case .tapSwipeOrInsertCard(inputMethods: let inputMethods, cancelPayment: let cancelPayment):
                cancelPayment()
            case .paymentSuccess(done: let done):
                done()
            case .paymentError(error: let error, tryAgain: let tryAgain, cancelPayment: let cancelPayment):
                cancelPayment()
            case .paymentErrorNonRetryable(error: let error, cancelPayment: let cancelPayment):
                cancelPayment()
            case .processing:
                cancelPayment()
            case .displayReaderMessage(message: let message):
                cancelPayment()
            /// An alert to notify the merchant that the transaction was cancelled using a button on the reader
            case .cancelledOnReader:
                cancelPayment()
            /// Before reader connection
            case .selectSearchType:
                cancelReaderSearch()
            /// Connection already completed, before attempting payment
            case .validatingOrder:
                return
        }
    }
}

private extension CardPresentPaymentCollectOrderPaymentUseCaseAdaptor {
    func cancelReaderSearch() {
        stores.dispatch(CardPresentPaymentAction.cancelCardReaderDiscovery() { [weak self] _ in
            //            self?.returnSuccess(result: .canceled(cancellationSource))
        })
    }

    func cancelReaderConnection() {
        // TODO
    }

    func cancelPayment() {
        stores.dispatch(CardPresentPaymentAction.cancelPayment() { [weak self] result in
            // TODO: implement allowPassPresentation when Tap To Pay is supported
//            self?.allowPassPresentation()
        })
    }
}
