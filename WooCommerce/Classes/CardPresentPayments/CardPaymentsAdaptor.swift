import Foundation
import Yosemite
import class WooFoundation.CurrencyFormatter

enum CardPresentPaymentResult {
    case success(Order)
    case failure(CardPaymentErrorProtocol)
    case cancellation
}

class CardPresentPaymentsAdaptor {
    private let currencyFormatter: CurrencyFormatter = CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)
    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
    }

    func collectPayment(for order: Order,
                        using discoveryMethod: CardReaderDiscoveryMethod) async -> CardPresentPaymentResult {
        let orderPaymentUseCase = await CollectOrderPaymentUseCase(siteID: siteID,
                                                                   order: order,
                                                                   formattedAmount: currencyFormatter.formatAmount(order.total, with: order.currency) ?? "",
                                                                   // moved from EditableOrderViewModel.collectPayment(for: Order)
                                                                   rootViewController: UIViewController(), 
                                                                   // We don't want to use this at all, but it's currently required by the existing code.
                                                                   // TODO: replace `rootViewController` with a protocol containing the UIVC functions we need, and implement that here.
                                                                   onboardingPresenter: self,
                                                                   configuration: CardPresentConfigurationLoader().configuration,
                                                                   alertsPresenter: self)
        return await withCheckedContinuation { continuation in
            orderPaymentUseCase.collectPayment(using: discoveryMethod) { error in
                if let error = error as? CardPaymentErrorProtocol {
                    continuation.resume(returning: .failure(error))
                } else {
                    continuation.resume(returning: .failure(CardPaymentsAdaptorError.unknownPaymentError(underlyingError: error)))
                }
            } onCancel: {
                continuation.resume(returning: .cancellation)
            } onPaymentCompletion: {
                // no-op – not used in PaymentMethodsViewModel anyway so this can be removed
            } onCompleted: {
                continuation.resume(returning: .success(order))
            }
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
}

struct CardPresentPaymentsAdaptorPaymentAlert {
    
}

