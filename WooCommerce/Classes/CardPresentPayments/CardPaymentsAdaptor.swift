import Foundation
import Yosemite
import class WooFoundation.CurrencyFormatter

class CardPresentPaymentsAdaptor {
    private let currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
    }

    /// The problem with this approach is that making the usecase also makes the preflight controller, which makes the two connection controllers.
    /// Each of these require the `alertPresenter`, and some require the `onboardingPresenter`.
    /// 
    /// Since this design has a short-lived `eventAdaptor` fulfilling both roles, we can't make a long-lived connection controller
    /// unless we change it to allow the alertsPresenter to be changed when `collectPayment` is called a second time.
    ///
    /// Having short-lived connection controllers means we would need another way to set a single source of truth for the reader connection.
    func collectPayment(for order: Order,
                        using discoveryMethod: CardReaderDiscoveryMethod) -> AsyncStream<CardPresentPaymentEvent> {
        let eventStream = AsyncStream<CardPresentPaymentEvent> { streamContinuation in
            let eventAdaptor = CardPresentPaymentsEventAdaptor(eventStreamContinuation: streamContinuation)

            let orderPaymentUseCase = CollectOrderPaymentUseCase(siteID: siteID,
                                                                 order: order,
                                                                 formattedAmount: currencyFormatter.formatAmount(order.total, with: order.currency) ?? "",
                                                                 // moved from EditableOrderViewModel.collectPayment(for: Order)
                                                                 rootViewController: UIViewController(),
                                                                 // We don't want to use this at all, but it's currently required by the existing code.
                                                                 // TODO: replace `rootViewController` with a protocol containing the UIVC functions we need, and implement that here.
                                                                 onboardingPresenter: eventAdaptor,
                                                                 configuration: CardPresentConfigurationLoader().configuration,
                                                                 alertsPresenter: eventAdaptor)
            orderPaymentUseCase.collectPayment(using: discoveryMethod) { error in
                if let error = error as? CardPaymentErrorProtocol {
                    streamContinuation.yield(.failure(error))
                } else {
                    streamContinuation.yield(.failure(CardPaymentsAdaptorError.unknownPaymentError(underlyingError: error)))
                    streamContinuation.finish()
                }
            } onCancel: {
                streamContinuation.yield(.cancellation)
                streamContinuation.finish()
            } onPaymentCompletion: {
                // no-op – not used in PaymentMethodsViewModel anyway so this can be removed
            } onCompleted: {
                streamContinuation.yield(.success(order))
                streamContinuation.finish()
            }
        }

        return eventStream
    }

    enum CardPaymentsAdaptorError: Error, CardPaymentErrorProtocol {
        var retryApproach: CardPaymentRetryApproach {
            .restart
        }

        case unknownPaymentError(underlyingError: Error)
    }
}

class CardPresentPaymentsEventAdaptor: CardPresentPaymentsOnboardingPresenting, CardPresentPaymentAlertsPresenting {
    let eventStreamContinuation: AsyncStream<CardPresentPaymentEvent>.Continuation

    init(eventStreamContinuation: AsyncStream<CardPresentPaymentEvent>.Continuation) {
        self.eventStreamContinuation = eventStreamContinuation
    }

    func showOnboardingIfRequired(from: UIViewController, readyToCollectPayment: @escaping () -> Void) {
        eventStreamContinuation.yield(.showOnboarding)
    }

    func refresh() {
        // TODO: Refresh onboarding
    }

    func present(viewModel: CardPresentPaymentsModalViewModel) {
        eventStreamContinuation.yield(.presentAlert(CardPresentPaymentsAdaptorPaymentAlert(from: viewModel)))
    }

    func foundSeveralReaders(readerIDs: [String], connect: @escaping (String) -> Void, cancelSearch: @escaping () -> Void) {
        eventStreamContinuation.yield(.presentReaderList(readerIDs))
    }

    func updateSeveralReadersList(readerIDs: [String]) {
        eventStreamContinuation.yield(.presentReaderList(readerIDs))
    }

    func dismiss() {
        eventStreamContinuation.yield(.dismissAlerts)
        // I don't know whether we _really_ need to implement this.
        // It seems better to dismiss implicitly (if we need to present something else) or if the user triggers it.
    }
}

enum CardPresentPaymentEvent {
    case presentAlert(CardPresentPaymentsAdaptorPaymentAlert)
    case presentReaderList(_ readerIDs: [String])
    case showOnboarding
    case dismissAlerts

    case success(Order)
    case failure(CardPaymentErrorProtocol)
    case cancellation
}

struct CardPresentPaymentsAdaptorPaymentAlert {
    init(from: CardPresentPaymentsModalViewModel) {

    }
}
