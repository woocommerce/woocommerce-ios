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

    private let onboardingPresenterAdaptor: CardPresentPaymentsOnboardingPresenterAdaptor

    var paymentsAlertHandler: CardPresentPaymentsAlertHandling?

    init(siteID: Int64) {
        self.siteID = siteID
        onboardingPresenterAdaptor = CardPresentPaymentsOnboardingPresenterAdaptor(stores: ServiceLocator.stores)
    }

    func collectPayment(for order: Order,
                        using discoveryMethod: CardReaderDiscoveryMethod) async -> CardPresentPaymentResult {
        let preflightController = await CardPresentPaymentPreflightController(
            siteID: siteID,
            configuration: CardPresentConfigurationLoader().configuration,
            rootViewController: UIViewController(),
            alertsPresenter: self,
            onboardingPresenter: onboardingPresenterAdaptor,
            bluetoothConnectionController: bluetoothConnectionController,
            builtInConnectionController: tapToPayConnectionController)
        let orderPaymentUseCase = await CollectOrderPaymentUseCase(siteID: siteID,
                                                                   order: order,
                                                                   formattedAmount: currencyFormatter.formatAmount(order.total, with: order.currency) ?? "",
                                                                   // moved from EditableOrderViewModel.collectPayment(for: Order)
                                                                   rootViewController: UIViewController(),
                                                                   // We don't want to use this at all, but it's currently required by the existing code.
                                                                   // TODO: replace `rootViewController` with a protocol containing the UIVC functions we need, and implement that here.
                                                                   onboardingPresenter: onboardingPresenterAdaptor,
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

extension CardPresentPaymentsAdaptor: CardPresentPaymentAlertsPresenting {

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

import Combine

/// This is really a re-implementation of the CardPresentPaymentsOnboardingPresenter, as it needs to take the calls to `showOnboardingIfRequired` and
/// route the output to a SwiftUI view for display, rather than directly displaying on the viewController that's passed in.
final class CardPresentPaymentsOnboardingPresenterAdaptor: CardPresentPaymentsOnboardingPresenting {
    private let stores: StoresManager

    private let onboardingUseCase: CardPresentPaymentsOnboardingUseCase

    private let readinessUseCase: CardPresentPaymentsReadinessUseCase

    private let onboardingViewModel: InPersonPaymentsViewModel

    private var readinessSubscription: AnyCancellable?

    var onboardingScreenViewModelPublisher: AnyPublisher<InPersonPaymentsViewModel?, Never>

    private var onboardingScreenViewModelSubject: PassthroughSubject<InPersonPaymentsViewModel?, Never> = PassthroughSubject()

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
        onboardingUseCase = CardPresentPaymentsOnboardingUseCase(stores: stores)
        readinessUseCase = CardPresentPaymentsReadinessUseCase(onboardingUseCase: onboardingUseCase, stores: stores)
        onboardingViewModel = InPersonPaymentsViewModel(useCase: onboardingUseCase)
        onboardingScreenViewModelPublisher = onboardingScreenViewModelSubject.eraseToAnyPublisher()
    }


    /// If the onboarding state is not `ready`, this will instruct downstream SwiftUI code to present the appropriate onboarding screen.
    /// - Parameters:
    ///   - viewController: This will be ignored, as other SwiftUI code is responsible for the display in this implementation.
    ///   - completion: Callback when the onboarding is complete
    func showOnboardingIfRequired(from viewController: UIViewController,
                                  readyToCollectPayment completion: @escaping () -> Void) {
        readinessUseCase.checkCardPaymentReadiness()
        guard case .ready = readinessUseCase.readiness else {
            return showOnboarding(readyToCollectPayment: completion)
        }
        completion()
    }

    private func showOnboarding(readyToCollectPayment completion: @escaping () -> Void) {
        onboardingScreenViewModelSubject.send(onboardingViewModel)

        // TODO: add the disappear closure to the OnboardingViewModel so that it can be used when we make the view.
//            .onDisappear { [weak self] in
//                self?.readinessSubscription?.cancel()
//            }

        readinessSubscription = readinessUseCase.$readiness
            .subscribe(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] readiness in
                guard let self,
                        case .ready = readiness else {
                    return
                }
                onboardingScreenViewModelSubject.send(nil)

                completion()
            })
    }

    func refresh() {
        onboardingUseCase.refreshIfNecessary()
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
    func showOnboarding(viewModel: InPersonPaymentsViewModel?)

    func present(_ alert: CardPresentPaymentsAdaptorPaymentAlert)

    func showReaderList(_ readerIDs: [String])

    func dismiss()
}
