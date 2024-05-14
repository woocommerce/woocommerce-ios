import Foundation
import Yosemite
import class WooFoundation.CurrencyFormatter

class CardPresentPaymentsAdaptor {
    private let currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
    }

    func collectPayment(for order: Order,
                        using discoveryMethod: CardReaderDiscoveryMethod) -> AsyncStream<CardPresentPaymentEvent> {
        var continuation: AsyncStream<CardPresentPaymentEvent>.Continuation!
        let eventStream = AsyncStream { cont in
            continuation = cont
        }
        // The problem is, we need to hold on to this stream at the class level, so that we can send events from the onboarding/alerts implementations.
        // That makes it long-lived and then it has to match the class's lifespan.
        // That stops us having a single source of truth for the reader connection (at least in this class.)

        let orderPaymentUseCase = CollectOrderPaymentUseCase(siteID: siteID,
                                                                   order: order,
                                                                   formattedAmount: currencyFormatter.formatAmount(order.total, with: order.currency) ?? "",
                                                                   // moved from EditableOrderViewModel.collectPayment(for: Order)
                                                                   rootViewController: UIViewController(), 
                                                                   // We don't want to use this at all, but it's currently required by the existing code.
                                                                   // TODO: replace `rootViewController` with a protocol containing the UIVC functions we need, and implement that here.
                                                                   onboardingPresenter: self,
                                                                   configuration: CardPresentConfigurationLoader().configuration,
                                                                   alertsPresenter: self)
        orderPaymentUseCase.collectPayment(using: discoveryMethod) { error in
            if let error = error as? CardPaymentErrorProtocol {
                continuation.yield(.failure(error))
            } else {
                continuation.yield(.failure(CardPaymentsAdaptorError.unknownPaymentError(underlyingError: error)))
                continuation.finish()
            }
        } onCancel: {
            continuation.yield(.cancellation)
            continuation.finish()
        } onPaymentCompletion: {
            // no-op – not used in PaymentMethodsViewModel anyway so this can be removed
        } onCompleted: {
            continuation.yield(.success(order))
            continuation.finish()
        }
    }

    enum CardPaymentsAdaptorError: Error, CardPaymentErrorProtocol {
        var retryApproach: CardPaymentRetryApproach {
            .restart
        }

        case unknownPaymentError(underlyingError: Error)
    }
}

extension CardPresentPaymentsAdaptor: CardPresentPaymentsOnboardingPresenting {
    func showOnboardingIfRequired(from: UIViewController, readyToCollectPayment: @escaping () -> Void) {
        
    }
    
    func refresh() {
        // TODO: Refresh onboarding
    }
}

extension CardPresentPaymentsAdaptor: CardPresentPaymentAlertsPresenting {
    func present(viewModel: CardPresentPaymentsModalViewModel) {
        <#code#>
    }
    
    func foundSeveralReaders(readerIDs: [String], connect: @escaping (String) -> Void, cancelSearch: @escaping () -> Void) {

    }
    
    func updateSeveralReadersList(readerIDs: [String]) {

    }
    
    func dismiss() {
        <#code#>
    }
}

enum CardPresentPaymentEvent {
    case presentAlert(CardPresentPaymentsAdaptorPaymentAlert)
    case presentReaderList(_ readerIDs: [String])
    case showOnboarding

    case success(Order)
    case failure(CardPaymentErrorProtocol)
    case cancellation
}

struct CardPresentPaymentsAdaptorPaymentAlert {
    
}

