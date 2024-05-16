import Foundation
import Yosemite
import class WooFoundation.CurrencyFormatter


protocol CardPresentPayments {

    /// The adaptor/facade is intended to be created once when we switch stores, and to be a singleton.
    /// We might as well make a new one when we switch stores though.
    init(siteID: Int64)

    /// `paymentScreenEventPublisher` provides a stream of events relating to a payment, including their view models,
    /// for subscribers to display to the user. e.g. onboarding screens, connection progress, payment progress, card reader messages
    /// We may want separate streams for these depending on the way we consume it
    var paymentScreenEventPublisher: AnyPublisher<CardPresentPaymentEvent?, Never> { get }

    /// Uses the existing code to connect to a reader, publishing intermediate events on the stream above as required.
    /// The end result of the payment is returned via async/await
    /// - Parameters:
    ///   - order: The order to collect payment for
    ///   - discoveryMethod: Allows specifying Tap to Pay or external reader. For POS, this would default to external.
    /// - Returns: `CardPresentPaymentResult` for a success, failure, or cancellation.
    func collectPayment(for order: Order,
                        using discoveryMethod: CardReaderDiscoveryMethod) async -> CardPresentPaymentResult

    func cancelPayment()

}

enum CardPresentPaymentResult {
    case success(Order)
    case failure(CardPaymentErrorProtocol)
    case cancellation
}

enum CardPresentPaymentEvent {
    case presentAlert(CardPresentPaymentsModalContent)
    case presentReaderList(_ readerIDs: [String])
    case showOnboarding(_ onboardingViewModel: InPersonPaymentsViewModel)
}

class CardPresentPaymentsAdaptor: CardPresentPayments {

    /// `paymentScreenEventPublisher` provides a stream of events relating to a payment, including their view models,
    /// for subscribers to display to the user.
    /// This is long lived, and used to display UI, not to communicate the success or failure of a particular payment
    // TODO: figure out whether there's any reason to use a Combine publisher or AsyncStream here.
    // TODO: decide whether we actually want to expose this, or just internally assign `paymentScreenEventSubject` to each short-lived stream instead.
    var paymentScreenEventPublisher: AnyPublisher<CardPresentPaymentEvent?, Never>

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

    private var paymentScreenEventSubject = CurrentValueSubject<CardPresentPaymentEvent?, Never>(nil)

    required init(siteID: Int64) {
        self.siteID = siteID
        onboardingPresenterAdaptor = CardPresentPaymentsOnboardingPresenterAdaptor(stores: ServiceLocator.stores)

        paymentScreenEventPublisher = onboardingPresenterAdaptor.onboardingScreenViewModelPublisher.map { onboardingViewModel -> CardPresentPaymentEvent? in
            guard let onboardingViewModel else {
                return nil
            }
            return CardPresentPaymentEvent.showOnboarding(onboardingViewModel)
        }
        .merge(with: paymentScreenEventSubject)
        .eraseToAnyPublisher()
    }

    private var paymentTask: Task<CardPresentPaymentResult, Never>?

    @MainActor
    func collectPayment(for order: Order,
                        using discoveryMethod: CardReaderDiscoveryMethod) async -> CardPresentPaymentResult {
        let preflightController = CardPresentPaymentPreflightController(
            siteID: siteID,
            configuration: CardPresentConfigurationLoader().configuration,
            rootViewController: UIViewController(),
            alertsPresenter: self,
            onboardingPresenter: onboardingPresenterAdaptor,
            bluetoothConnectionController: bluetoothConnectionController,
            builtInConnectionController: tapToPayConnectionController)
        let orderPaymentUseCase = CollectOrderPaymentUseCase(siteID: siteID,
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
        paymentTask?.cancel()

        let paymentTask = Task {
            return await withTaskCancellationHandler {
                return await withCheckedContinuation { continuation in
                    orderPaymentUseCase.collectPayment(using: discoveryMethod) { error in
                        // TODO: even though we have a tri-state result type, perhaps we should throw these errors.
                        if let error = error as? CardPaymentErrorProtocol {
                            continuation.resume(returning: CardPresentPaymentResult.failure(error))
                        } else {
                            continuation.resume(returning: CardPresentPaymentResult.failure(CardPaymentsAdaptorError.unknownPaymentError(underlyingError: error)))
                        }
                    } onCancel: {
                        continuation.resume(returning: CardPresentPaymentResult.cancellation)
                    } onPaymentCompletion: {
                        // no-op – not used in PaymentMethodsViewModel anyway so this can be removed
                    } onCompleted: {
                        continuation.resume(returning: CardPresentPaymentResult.success(order))
                    }
                }
            } onCancel: {
                // TODO: cancel any in-progress discovery, connection, or payment.
            }
        }
        self.paymentTask = paymentTask

        return await paymentTask.value
    }

    func cancelPayment() {
        paymentTask?.cancel()
        paymentScreenEventSubject.send(nil) // This removes any otherwise-presented UI
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
        paymentScreenEventSubject.send(.presentAlert(viewModel as CardPresentPaymentsModalContent))
    }

    func foundSeveralReaders(readerIDs: [String], connect: @escaping (String) -> Void, cancelSearch: @escaping () -> Void) {
        paymentScreenEventSubject.send(.presentReaderList(readerIDs))
        // the button actions here might need to be communicated... or we could expose them on the adaptor somehow.
    }

    func updateSeveralReadersList(readerIDs: [String]) {
        paymentScreenEventSubject.send(.presentReaderList(readerIDs))
    }

    func dismiss() {
        paymentScreenEventSubject.send(nil)
        // TODO: Decide whether we really need this
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
                // TODO: perhaps we should have a more specific "success" event here.
                // At the moment, this clears the screen of the onboarding flow, and then another screen would get presented
                // Since we merge this subject with the payment alerts subject, the existing behaviour might not be ideal
                // because it will lead to a dismissal, then a new presentation.
                onboardingScreenViewModelSubject.send(nil)

                completion()
            })
    }

    func refresh() {
        onboardingUseCase.refreshIfNecessary()
    }

}
