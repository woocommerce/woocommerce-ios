import Combine
import Foundation
import struct Yosemite.Order
import struct Yosemite.CardPresentPaymentsConfiguration
import struct Yosemite.CardReader
import enum Yosemite.CardPresentPaymentAction
import protocol Yosemite.StoresManager

final class CardPresentPaymentService: CardPresentPaymentFacade {
    let paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never>

    let connectedReaderPublisher: AnyPublisher<CardPresentPaymentCardReader?, Never>

    private let paymentEventSubject = PassthroughSubject<CardPresentPaymentEvent, Never>()

    private let onboardingAdaptor: CardPresentPaymentsOnboardingPresenterAdaptor

    private let paymentAlertsPresenterAdaptor: CardPresentPaymentsAlertPresenterAdaptor
    private let connectionControllerManager: CardPresentPaymentsConnectionControllerManager

    private let siteID: Int64

    private var cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration {
        CardPresentConfigurationLoader().configuration
    }

    private var paymentTask: Task<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error>?

    @MainActor
    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) async {
        self.siteID = siteID
        let onboardingAdaptor = CardPresentPaymentsOnboardingPresenterAdaptor()
        self.onboardingAdaptor = onboardingAdaptor
        let paymentAlertsPresenterAdaptor = CardPresentPaymentsAlertPresenterAdaptor()
        self.paymentAlertsPresenterAdaptor = paymentAlertsPresenterAdaptor
        connectionControllerManager = CardPresentPaymentsConnectionControllerManager(
            siteID: siteID,
            configuration: CardPresentConfigurationLoader().configuration,
            alertsPresenter: paymentAlertsPresenterAdaptor)

        paymentEventPublisher = onboardingAdaptor.onboardingScreenViewModelPublisher
            .map { onboardingEvent -> CardPresentPaymentEvent in
                switch onboardingEvent {
                case .showOnboarding(let onboardingViewModel):
                    return .showOnboarding(onboardingViewModel)
                case .onboardingComplete:
                    return .idle
                }
            }
            .merge(with: paymentAlertsPresenterAdaptor.paymentAlertPublisher)
            .merge(with: paymentEventSubject)
            .receive(on: DispatchQueue.main) // These will be used for UI changes, so moving to the Main thread helps.
            .eraseToAnyPublisher()

        connectedReaderPublisher = await Self.createCardReaderConnectionPublisher(stores: stores)
    }

    @MainActor
    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        // What happens if this gets called while there's another connection ongoing?
        let preflightControllerAdaptor = CardPresentPaymentPreflightAdaptor(preflightController: createPreflightController())

        let preflightResult = try await preflightControllerAdaptor.attemptConnection(discoveryMethod: connectionMethod.discoveryMethod)

        switch preflightResult {
        case .completed(let cardReader, _):
            let connectedReader = CardPresentPaymentCardReader(name: cardReader.name ?? cardReader.id,
                                                               batteryLevel: cardReader.batteryLevel)
            paymentEventSubject.send(.idle)
            return .connected(connectedReader)
        case .canceled:
            paymentEventSubject.send(.idle)
            return .canceled
        }
    }

    func disconnectReader() {
    }

    @MainActor
    func collectPayment(for order: Order, using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentResult {
        paymentTask?.cancel()

        // What happens if `start` gets called while there's a connection ongoing but not finished?
        // Ideally, we'd adopt the connection attempt.
        // Since we're reusing the connection controllers, that's a good start, but it needs proper testing.
        let preflightController = createPreflightController()

        // TODO: Update the connected reader subject when we get a connection here.

        let paymentTask = CardPresentPaymentCollectOrderPaymentUseCaseAdaptor().collectPaymentTask(
            for: order,
            using: connectionMethod,
            siteID: siteID,
            preflightController: preflightController,
            onboardingPresenter: onboardingAdaptor,
            configuration: cardPresentPaymentsConfiguration,
            alertsPresenter: paymentAlertsPresenterAdaptor,
            paymentEventSubject: paymentEventSubject)

        self.paymentTask = paymentTask

        switch try await paymentTask.value {
        case .success:
            // TODO: fetch the receipt URL to return an accurate value.
            let transaction = CardPresentPaymentTransaction(receiptURL: URL(string: "https://example.com")!)
            return .success(transaction)
        case .cancellation:
            return .cancellation
        }
    }

    func cancelPayment() {
        paymentTask?.cancel()
    }
}

private extension CardPresentPaymentService {
    @MainActor
    static func createCardReaderConnectionPublisher(stores: StoresManager) async -> AnyPublisher<CardPresentPaymentCardReader?, Never> {
        return await withCheckedContinuation { continuation in
            var nillableContinuation: CheckedContinuation<AnyPublisher<CardPresentPaymentCardReader?, Never>, Never>? = continuation

            let action = CardPresentPaymentAction.publishCardReaderConnections { cardReadersConnectionPublisher in
                let readerConnectionPublisher = cardReadersConnectionPublisher
                    .map { readers -> CardPresentPaymentCardReader? in
                        guard let reader = readers.first else {
                            return nil
                        }
                        return CardPresentPaymentCardReader(name: reader.name ?? reader.id,
                                                            batteryLevel: reader.batteryLevel)
                    }
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()

                nillableContinuation?.resume(returning: readerConnectionPublisher)
                nillableContinuation = nil
            }
            stores.dispatch(action)
        }
    }

    func createPreflightController() -> CardPresentPaymentPreflightController {
        return CardPresentPaymentPreflightController(
            siteID: siteID,
            configuration: cardPresentPaymentsConfiguration,
            rootViewController: NullViewControllerPresenting(),
            alertsPresenter: paymentAlertsPresenterAdaptor,
            onboardingPresenter: onboardingAdaptor,
            externalReaderConnectionController: connectionControllerManager.externalReaderConnectionController,
            tapToPayConnectionController: connectionControllerManager.tapToPayConnectionController,
            tapToPayAlertProvider: BuiltInReaderConnectionAlertsProvider(),
            analyticsTracker: connectionControllerManager.analyticsTracker)
    }
}

enum CardPresentPaymentServiceError: Error {
    case invalidAmount
    case unknownPaymentError(underlyingError: Error)
}
