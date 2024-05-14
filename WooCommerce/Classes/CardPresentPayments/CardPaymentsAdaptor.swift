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
    var paymentsAlertHandler: CardPresentPaymentsAlertHandling?

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

extension CardPresentPaymentsAdaptor: CardPresentPaymentsOnboardingPresenting, CardPresentPaymentAlertsPresenting {
    func showOnboardingIfRequired(from: UIViewController, readyToCollectPayment: @escaping () -> Void) {
        paymentsAlertHandler?.showOnboarding()
    }

    func refresh() {
        // TODO: Refresh onboarding
    }

    func present(viewModel: CardPresentPaymentsModalViewModel) {
        paymentsAlertHandler?.present(CardPresentPaymentsAdaptorPaymentAlert(from: viewModel))
    }

    func foundSeveralReaders(readerIDs: [String], connect: @escaping (String) -> Void, cancelSearch: @escaping () -> Void) {
        paymentsAlertHandler?.showReaderList(readerIDs)
        // the button actions here might need to be communicated... or we could expose them on the adaptor somehow.
    }

    func updateSeveralReadersList(readerIDs: [String]) {
        paymentsAlertHandler?.showReaderList(readerIDs)
    }

    func dismiss() {
        paymentsAlertHandler?.dismiss()
        // We might not really need this
    }
}

enum CardPresentPaymentEvent {
    case presentAlert(CardPresentPaymentsAdaptorPaymentAlert)
    case presentReaderList(_ readerIDs: [String])
    case showOnboarding
}

struct CardPresentPaymentsAdaptorPaymentAlert {
    init(from paymentsModalViewModel: CardPresentPaymentsModalViewModel) {
        // In here we still need to handle the button actions wrt the UIViewControllers the closures are passed.
        // That said, very few of the alerts actually use the UIVCs, so it might be just as easy to remove the dependency from both sides
    }
}

protocol CardPresentPaymentsAlertHandling {
    func showOnboarding()

    func present(_ alert: CardPresentPaymentsAdaptorPaymentAlert)

    func showReaderList(_ readerIDs: [String])

    func dismiss()
}
