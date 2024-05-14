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

    // These connection controllers shouldn't be lazy, I'm just being lazy.
    // They're lazy because of `self` implementing `alertsPresenter`.
    // If that were done by another owned struct, and the handler passed to it as and when it changed, we could do this in the init.
    private lazy var bluetoothConnectionController: CardReaderConnectionController = {
        CardReaderConnectionController(
            forSiteID: siteID,
            knownReaderProvider: CardReaderSettingsKnownReaderStorage(),
            alertsPresenter: self,
            alertsProvider: BluetoothReaderConnectionAlertsProvider(),
            configuration: CardPresentConfigurationLoader().configuration,
            analyticsTracker: CardReaderConnectionAnalyticsTracker(
                configuration: CardPresentConfigurationLoader().configuration,
                siteID: siteID,
                connectionType: .userInitiated, // This will need a tweak – it changes from use to use.
                analytics: ServiceLocator.analytics))
    }()

    private lazy var tapToPayConnectionController: BuiltInCardReaderConnectionController = {
        BuiltInCardReaderConnectionController(
            forSiteID: siteID,
            alertsPresenter: self,
            alertsProvider: BluetoothReaderConnectionAlertsProvider(),
            configuration: CardPresentConfigurationLoader().configuration,
            analyticsTracker: CardReaderConnectionAnalyticsTracker(
                configuration: CardPresentConfigurationLoader().configuration,
                siteID: siteID,
                connectionType: .userInitiated, // This will need a tweak – it changes from use to use.
                analytics: ServiceLocator.analytics))
    }()

    var paymentsAlertHandler: CardPresentPaymentsAlertHandling?

    init(siteID: Int64) {
        self.siteID = siteID
    }

    func collectPayment(for order: Order,
                        using discoveryMethod: CardReaderDiscoveryMethod) async -> CardPresentPaymentResult {
        let preflightController = await CardPresentPaymentPreflightController(
            siteID: siteID,
            configuration: CardPresentConfigurationLoader().configuration,
            rootViewController: UIViewController(),
            alertsPresenter: self,
            onboardingPresenter: self,
            bluetoothConnectionController: bluetoothConnectionController,
            builtInConnectionController: tapToPayConnectionController)
        let orderPaymentUseCase = await CollectOrderPaymentUseCase(siteID: siteID,
                                                                   order: order,
                                                                   formattedAmount: currencyFormatter.formatAmount(order.total, with: order.currency) ?? "",
                                                                   // moved from EditableOrderViewModel.collectPayment(for: Order)
                                                                   rootViewController: UIViewController(),
                                                                   // We don't want to use this at all, but it's currently required by the existing code.
                                                                   // TODO: replace `rootViewController` with a protocol containing the UIVC functions we need, and implement that here.
                                                                   onboardingPresenter: self,
                                                                   configuration: CardPresentConfigurationLoader().configuration,
                                                                   alertsPresenter: self,
                                                                   preflightController: preflightController)
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
