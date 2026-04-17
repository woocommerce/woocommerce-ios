import Combine
import PointOfSale
import Foundation
import struct Yosemite.Order
import struct Yosemite.CardPresentPaymentsConfiguration
import struct Yosemite.CardReader
import enum Yosemite.CardPresentPaymentAction
import enum Yosemite.PaymentChannel
import enum Hardware.CardReaderSoftwareUpdateState
import protocol Yosemite.StoresManager

final class CardPresentPaymentService: CardPresentPaymentFacade {
    let paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never>

    let readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never>

    let cardReaderUpdateStatePublisher: AnyPublisher<CardReaderSoftwareUpdateState, Never>

    private let connectedReaderPublisher: AnyPublisher<CardPresentPaymentCardReader?, Never>

    private let paymentEventSubject = PassthroughSubject<CardPresentPaymentEvent, Never>()

    private let readerConnectionStatusSubject = PassthroughSubject<CardPresentPaymentReaderConnectionStatus, Never>()

    private let onboardingAdaptor: CardPresentPaymentsOnboardingPresenterAdaptor

    private let paymentAlertsPresenterAdaptor: CardPresentPaymentsAlertPresenterAdaptor
    private let connectionControllerManager: CardPresentPaymentsConnectionControllerManager

    private let siteID: Int64
    private let stores: StoresManager
    private let collectOrderPaymentAnalyticsTracker: CollectOrderPaymentAnalyticsTracking

    private var cardPresentPaymentsConfiguration: CardPresentPaymentsConfiguration {
        CardPresentConfigurationLoader().configuration
    }

    private var paymentTask: Task<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error>?

    @MainActor
    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores, collectOrderPaymentAnalyticsTracker: CollectOrderPaymentAnalyticsTracking) async {
        self.siteID = siteID
        let onboardingAdaptor = CardPresentPaymentsOnboardingPresenterAdaptor()
        self.onboardingAdaptor = onboardingAdaptor
        let paymentAlertsPresenterAdaptor = CardPresentPaymentsAlertPresenterAdaptor()
        self.paymentAlertsPresenterAdaptor = paymentAlertsPresenterAdaptor
        self.stores = stores
        self.collectOrderPaymentAnalyticsTracker = collectOrderPaymentAnalyticsTracker

        connectionControllerManager = CardPresentPaymentsConnectionControllerManager(
            siteID: siteID,
            configuration: CardPresentConfigurationLoader().configuration,
            alertsPresenter: paymentAlertsPresenterAdaptor)

        paymentEventPublisher = onboardingAdaptor.onboardingScreenViewModelPublisher
            .map { onboardingEvent -> CardPresentPaymentEvent in
                switch onboardingEvent {
                case let .showOnboarding(factory, onCancel):
                    return .showOnboarding(factory: factory, onCancel: onCancel)
                case .onboardingComplete:
                    return .idle
                }
            }
            .merge(with: paymentAlertsPresenterAdaptor.paymentEventPublisher)
            .merge(with: paymentEventSubject)
            .receive(on: DispatchQueue.main) // These will be used for UI changes, so moving to the Main thread helps.
            .eraseToAnyPublisher()

        let connectedReaderPublisher = await Self.createCardReaderConnectionPublisher(stores: stores)
        self.connectedReaderPublisher = connectedReaderPublisher

        readerConnectionStatusPublisher = self.connectedReaderPublisher
            .map({ reader -> CardPresentPaymentReaderConnectionStatus in
                guard let reader else {
                    return .disconnected
                }
                return .connected(reader)
            })
            .merge(with: paymentAlertsPresenterAdaptor.readerConnectionStatusPublisher)
            .merge(with: readerConnectionStatusSubject)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        let updateStatePublisher = await Self.createUpdateStatePublisher(stores: stores)
        self.cardReaderUpdateStatePublisher = updateStatePublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    @MainActor
    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        // What happens if this gets called while there's another connection ongoing?
        let preflightControllerAdaptor = CardPresentPaymentPreflightAdaptor(preflightController: createPreflightController())

        let preflightResult = try await preflightControllerAdaptor.attemptConnection(discoveryMethod: connectionMethod.discoveryMethod)

        switch preflightResult {
        case .completed(let cardReader, _):
            let connectedReader = CardPresentPaymentCardReader(name: cardReader.name ?? cardReader.id,
                                                               batteryLevel: cardReader.batteryLevel,
                                                               softwareVersion: cardReader.softwareVersion)
            paymentEventSubject.send(.show(eventDetails: .connectionSuccess(done: { [weak self] in
                self?.paymentEventSubject.send(.idle)
            })))
            return .connected(connectedReader)
        case .canceled:
            readerConnectionStatusSubject.send(.disconnected)
            paymentEventSubject.send(.idle)
            return .canceled
        }
    }

    @MainActor
    func disconnectReader() async {
        readerConnectionStatusSubject.send(.disconnecting)

        do {
            try await cancelPayment()
        } catch {
            DDLogError("Attempting to cancel the payment has failed \(error)")
        }

        connectionControllerManager.knownReaderProvider.forgetCardReader()

        return await withCheckedContinuation { continuation in
            var nillableContinuation: CheckedContinuation<Void, Never>? = continuation

            let action = CardPresentPaymentAction.disconnect { [weak self] _ in
                // Disconnections typically fail because the reader is not connected in the first place.
                // Assuming we're disconnected allows further connection attempts, which can resolve the situation.
                // Connection attempts with a reader already connected succeed immediately.
                // Therefore, send disconnected for both success and failure results.
                self?.readerConnectionStatusSubject.send(.disconnected)
                nillableContinuation?.resume()
                nillableContinuation = nil
            }
            stores.dispatch(action)
        }
    }

    @MainActor
    func updateCardReaderSoftware() async throws {
        let action = CardPresentPaymentAction.startCardReaderUpdate
        stores.dispatch(action)
    }

    @MainActor
    func collectPayment(for order: Order, using connectionMethod: CardReaderConnectionMethod, channel: PaymentChannel) async throws -> CardPresentPaymentResult {
        paymentTask?.cancel()

        // What happens if `start` gets called while there's a connection ongoing but not finished?
        // Ideally, we'd adopt the connection attempt.
        // Since we're reusing the connection controllers, that's a good start, but it needs proper testing.
        let preflightController = createPreflightController()

        // TODO: Update the connected reader subject when we get a connection here.

        let paymentTask = CardPresentPaymentCollectOrderPaymentUseCaseAdaptor(paymentEventPublisher: paymentEventPublisher,
                                                                              collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker
        ).collectPaymentTask(
            for: order,
            using: connectionMethod,
            siteID: siteID,
            preflightController: preflightController,
            configuration: cardPresentPaymentsConfiguration,
            alertsPresenter: paymentAlertsPresenterAdaptor,
            paymentEventSubject: paymentEventSubject,
            channel: channel)

        self.paymentTask = paymentTask

        switch try await paymentTask.value {
        case .success(let capturedPaymentData):

            // TODO: fetch the receipt URL to return an accurate value.
            let transaction = CardPresentPaymentTransaction(
                receiptURL: URL(string: "https://example.com")!,
                receiptParameters: capturedPaymentData.receiptParameters)
            return .success(transaction)
        case .cancellation:
            return .cancellation
        }
    }

    func cancelPayment() {
        cancelPaymentTask()
    }

    @MainActor
    func cancelPayment() async throws {
        try await withCheckedThrowingContinuation { continuation in
            var nillableContinuation: CheckedContinuation<Void, any Error>? = continuation
            let action = CardPresentPaymentAction.cancelPayment { result in
                nillableContinuation?.resume(with: result)
                nillableContinuation = nil
            }
            stores.dispatch(action)
        }
    }

    private func cancelPaymentTask() {
        paymentTask?.cancel()
        paymentTask = nil
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
                                                            batteryLevel: reader.batteryLevel,
                                                            softwareVersion: reader.softwareVersion)
                    }
                    .receive(on: DispatchQueue.main)
                    .eraseToAnyPublisher()

                nillableContinuation?.resume(returning: readerConnectionPublisher)
                nillableContinuation = nil
            }
            stores.dispatch(action)
        }
    }

    @MainActor
    static func createUpdateStatePublisher(stores: StoresManager) async -> AnyPublisher<CardReaderSoftwareUpdateState, Never> {
        return await withCheckedContinuation { continuation in
            var nillableContinuation: CheckedContinuation<AnyPublisher<CardReaderSoftwareUpdateState, Never>, Never>? = continuation

            let action = CardPresentPaymentAction.observeCardReaderUpdateState { updateStatePublisher in
                nillableContinuation?.resume(returning: updateStatePublisher)
                nillableContinuation = nil
            }
            stores.dispatch(action)
        }
    }

    func createPreflightController() -> CardPresentPaymentPreflightController<
        CardPresentPaymentTapToPayReaderConnectionAlertsProvider,
        CardPresentPaymentBluetoothReaderConnectionAlertsProvider,
        CardPresentPaymentsAlertPresenterAdaptor> {
            let alertProvider = CardPresentPaymentTapToPayReaderConnectionAlertsProvider()
            return CardPresentPaymentPreflightController(
                siteID: siteID,
                configuration: cardPresentPaymentsConfiguration,
                rootViewController: NullViewControllerPresenting(),
                alertsPresenter: paymentAlertsPresenterAdaptor,
                onboardingPresenter: onboardingAdaptor,
                tapToPayAlertProvider: alertProvider,
                externalReaderConnectionController: connectionControllerManager.externalReaderConnectionController,
                tapToPayConnectionController: connectionControllerManager.tapToPayConnectionController,
                tapToPayReconnectionController: TapToPayReconnectionController(
                    connectionControllerFactory: TapToPayCardReaderConnectionControllerFactory(
                        alertProvider: alertProvider)),
                analyticsTracker: connectionControllerManager.analyticsTracker)
        }
}

enum CardPresentPaymentServiceError: Error {
    case invalidAmount
    case unknownPaymentError(underlyingError: Error)
    case incompleteAddressConnectionError
    case couldNotCancelPayment
}
