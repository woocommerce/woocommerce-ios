import Combine
import PointOfSale
import Foundation
import struct Yosemite.Order
import struct Yosemite.CardPresentPaymentsConfiguration
import struct Yosemite.CardReader
import enum Yosemite.CardReaderServiceError
import enum Yosemite.CardPresentPaymentAction
import enum Yosemite.PaymentChannel
import enum Yosemite.CardReaderSoftwareUpdateState
import enum Yosemite.CardReaderReconnectionState
import protocol Yosemite.StoresManager

@MainActor
final class CardPresentPaymentService: CardPresentPaymentFacade {
    var paymentEventPublisher: AnyPublisher<CardPresentPaymentEvent, Never> {
        onboardingAdaptor.onboardingScreenViewModelPublisher
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
            .map { (nil as UUID?, $0) }
            .merge(with: attemptEventSubject.map { (Optional($0.0), $0.1) })
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] attemptID, event in
                guard attemptID == nil || self?.paymentAttemptID == attemptID else { return nil }
                return event
            }
            .eraseToAnyPublisher()
    }

    let readerConnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never>

    let cardReaderUpdateStatePublisher: AnyPublisher<CardReaderSoftwareUpdateState, Never>

    private let connectedReaderPublisher: AnyPublisher<CardPresentPaymentCardReader?, Never>

    private let reconnectionStatusPublisher: AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never>

    private let attemptEventSubject = PassthroughSubject<(UUID, CardPresentPaymentEvent), Never>()

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

    // Stripe Terminal has one payment owner across POS flows and store changes. A process restart has no owner.
    private static var pendingPaymentOwner: CardPresentPaymentService?
    private static let paymentSessionStateSubject = CurrentValueSubject<CardPresentPaymentSessionState, Never>(.idle)
    var paymentSessionState: CardPresentPaymentSessionState { Self.paymentSessionStateSubject.value }
    var paymentSessionStatePublisher: AnyPublisher<CardPresentPaymentSessionState, Never> {
        Self.paymentSessionStateSubject.eraseToAnyPublisher()
    }
    private var paymentAttemptID: UUID?
    private enum PaymentAttemptPhase {
        case collecting
        case awaitingCapture
        case completed
    }
    private var paymentAttemptPhase: PaymentAttemptPhase?
    private var cancellationTask: Task<Void, Error>?

    private let paymentTaskFactory: (@MainActor (Order, CardReaderConnectionMethod, PaymentChannel, @escaping @MainActor () -> Void)
        -> Task<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error>)?
    private var paymentTask: Task<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error>?
    private var connectReaderTask: Task<CardPresentPaymentReaderConnectionResult, Error>?

    @MainActor
    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores, collectOrderPaymentAnalyticsTracker: CollectOrderPaymentAnalyticsTracking,
         paymentTaskFactory: (@MainActor (Order, CardReaderConnectionMethod, PaymentChannel, @escaping @MainActor () -> Void)
            -> Task<CardPresentPaymentAdaptedCollectOrderPaymentResult, Error>)? = nil) async {
        self.siteID = siteID
        self.paymentTaskFactory = paymentTaskFactory
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


        let connectedReaderPublisher = Self.createCardReaderConnectionPublisher(stores: stores)
        self.connectedReaderPublisher = connectedReaderPublisher

        let reconnectionStatusPublisher = Self.createReconnectionStatusPublisher(stores: stores)
        self.reconnectionStatusPublisher = reconnectionStatusPublisher

        readerConnectionStatusPublisher = self.connectedReaderPublisher
            .map({ reader -> CardPresentPaymentReaderConnectionStatus in
                guard let reader else {
                    return .disconnected
                }
                return .connected(reader)
            })
            .merge(with: paymentAlertsPresenterAdaptor.readerConnectionStatusPublisher)
            .merge(with: readerConnectionStatusSubject)
            .merge(with: reconnectionStatusPublisher)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()

        let updateStatePublisher = Self.createUpdateStatePublisher(stores: stores)
        self.cardReaderUpdateStatePublisher = updateStatePublisher
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    @MainActor
    func connectReader(using connectionMethod: CardReaderConnectionMethod) async throws -> CardPresentPaymentReaderConnectionResult {
        if let existingTask = connectReaderTask {
            existingTask.cancel()
            _ = try? await existingTask.value
        }

        let task = Task { @MainActor [weak self] () throws -> CardPresentPaymentReaderConnectionResult in
            guard let self else { return .canceled }
            defer { self.connectReaderTask = nil }

            let preflightControllerAdaptor = CardPresentPaymentPreflightAdaptor(preflightController: self.createPreflightController())
            do {
                let preflightResult = try await preflightControllerAdaptor.attemptConnection(discoveryMethod: connectionMethod.discoveryMethod)
                switch preflightResult {
                case .completed(let cardReader, _):
                    let connectedReader = CardPresentPaymentCardReader(name: cardReader.name ?? cardReader.id,
                                                                       batteryLevel: cardReader.batteryLevel,
                                                                       softwareVersion: cardReader.softwareVersion)
                    self.readerConnectionStatusSubject.send(.connected(connectedReader))
                    self.paymentEventSubject.send(.show(eventDetails: .connectionSuccess(done: { [weak self] in
                        self?.paymentEventSubject.send(.idle)
                    })))
                    return .connected(connectedReader)
                case .canceled:
                    self.readerConnectionStatusSubject.send(.disconnected)
                    self.paymentEventSubject.send(.idle)
                    return .canceled
                }
            } catch is CancellationError {
                await self.cancelReaderConnectionAttempt()
                return .canceled
            } catch {
                DDLogError("⛔️ Card reader connection failed: \(error.localizedDescription)")
                await self.cancelReaderConnectionAttempt()
                throw error
            }
        }

        connectReaderTask = task
        return try await task.value
    }

    @MainActor
    func disconnectReader() async {
        readerConnectionStatusSubject.send(.disconnecting)

        do {
            try await cancelPayment()
        } catch {
            DDLogError("Attempting to cancel the payment has failed \(error)")
            return
        }
        guard !paymentSessionState.isPending else { return }

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
        guard !paymentSessionState.isPending else { throw CardPresentPaymentServiceError.couldNotCancelPayment }
        let attemptID = UUID()
        paymentAttemptID = attemptID
        paymentAttemptPhase = .collecting
        Self.pendingPaymentOwner = self
        Self.paymentSessionStateSubject.send(.active)
        collectOrderPaymentAnalyticsTracker.clearPaymentConfirmation()

        // What happens if `start` gets called while there's a connection ongoing but not finished?
        // Ideally, we'd adopt the connection attempt.
        // Since we're reusing the connection controllers, that's a good start, but it needs proper testing.
        let alertsPresenter = CardPresentPaymentsAlertPresenterAdaptor()
        let attemptEvents = PassthroughSubject<CardPresentPaymentEvent, Never>()
        let eventSubscription = alertsPresenter.paymentEventPublisher.merge(with: attemptEvents)
            .sink { [weak self] event in self?.attemptEventSubject.send((attemptID, event)) }
        defer { eventSubscription.cancel() }
        let preflightController = createPreflightController(alertsPresenter: alertsPresenter)

        // TODO: Update the connected reader subject when we get a connection here.

        let adaptor = CardPresentPaymentCollectOrderPaymentUseCaseAdaptor(
            paymentEventPublisher: paymentEventPublisher,
            stores: stores,
            collectOrderPaymentAnalyticsTracker: collectOrderPaymentAnalyticsTracker)
        let onProcessingCompletion: @MainActor () -> Void = { [weak self] in
            guard let self, self.paymentAttemptID == attemptID, self.paymentAttemptPhase != .completed else { return }
            self.paymentAttemptPhase = .awaitingCapture
        }
        let paymentTask = paymentTaskFactory?(order, connectionMethod, channel, onProcessingCompletion) ?? adaptor.collectPaymentTask(
            for: order,
            using: connectionMethod,
            siteID: siteID,
            preflightController: preflightController,
            configuration: cardPresentPaymentsConfiguration,
            alertsPresenter: alertsPresenter,
            paymentEventSubject: attemptEvents,
            channel: channel,
            onProcessingCompletion: onProcessingCompletion)

        self.paymentTask = paymentTask

        do {
            let result = try await paymentTask.value
            guard paymentAttemptID == attemptID else { throw CancellationError() }
            paymentAttemptPhase = .completed
            if cancellationTask == nil { resolvePayment(attemptID) }
            switch result {
            case .success(let cardDetails):
                return .success(CardPresentPaymentTransaction(cardDetails: cardDetails))
            case .cancellation:
                return .cancellation
            }
        } catch {
            if paymentAttemptID == attemptID, cancellationTask == nil {
                Self.paymentSessionStateSubject.send(.unresolved)
            }
            throw error
        }
    }

    func cancelPayment() {
        guard paymentSessionState.isPending else { return }
        Task { @MainActor in
            do { try await self.cancelPayment() }
            catch { DDLogError("Failed to cancel POS payment: \(error)") }
        }
    }

    func cancelPayment() async throws {
        if let owner = Self.pendingPaymentOwner, owner !== self { return try await owner.cancelPayment() }
        if let cancellationTask { return try await cancellationTask.value }
        let attemptID = paymentAttemptID
        let task = Task { @MainActor in
            if attemptID != nil {
                Self.paymentSessionStateSubject.send(.cancelling)
                // Invalidate startup before asking Hardware to cancel; no later preflight callback may start collection.
                self.paymentTask?.cancel()
            }
            self.collectOrderPaymentAnalyticsTracker.clearPaymentConfirmation()
            do {
                try await self.cancelSDKPayment()
                self.cancellationTask = nil
                if let attemptID { self.resolvePayment(attemptID) }
            } catch {
                self.cancellationTask = nil
                if attemptID == nil, self.paymentSessionState == .idle,
                   case CardReaderServiceError.paymentCancellation(.noActivePaymentIntent) = error { return }
                if let attemptID, self.paymentAttemptID == attemptID {
                    switch error {
                    // The SDK clears its intent before backend capture finishes, so absence alone cannot settle that outcome.
                    case CardReaderServiceError.paymentCancellation(.noActivePaymentIntent) where self.paymentAttemptPhase != .awaitingCapture:
                        self.resolvePayment(attemptID)
                        return
                    default:
                        if self.paymentAttemptPhase == .completed {
                            self.resolvePayment(attemptID)
                        } else {
                            Self.paymentSessionStateSubject.send(.unresolved)
                        }
                    }
                }
                throw error
            }
        }
        cancellationTask = task
        try await task.value
    }

    private func resolvePayment(_ attemptID: UUID) {
        guard paymentAttemptID == attemptID else { return }
        paymentAttemptID = nil
        paymentAttemptPhase = nil
        paymentTask = nil
        if Self.pendingPaymentOwner === self { Self.pendingPaymentOwner = nil }
        Self.paymentSessionStateSubject.send(.idle)
    }

    private func cancelSDKPayment() async throws {
        try await withCheckedThrowingContinuation { continuation in
            var pending: CheckedContinuation<Void, Error>? = continuation
            stores.dispatch(CardPresentPaymentAction.cancelPayment { result in
                pending?.resume(with: result)
                pending = nil
            })
        }
    }

    @MainActor
    private func cancelReaderConnectionAttempt() async {
        paymentAlertsPresenterAdaptor.dismiss()

        await withCheckedContinuation { continuation in
            var nillableContinuation: CheckedContinuation<Void, Never>? = continuation

            let action = CardPresentPaymentAction.cancelCardReaderDiscovery { _ in
                nillableContinuation?.resume()
                nillableContinuation = nil
            }
            stores.dispatch(action)
        }
    }

    func cancelReconnection() async {
        await withCheckedContinuation { continuation in
            var nillableContinuation: CheckedContinuation<Void, Never>? = continuation

            let action = CardPresentPaymentAction.cancelReconnection { result in
                if case .failure(let error) = result {
                    DDLogError("Failed to cancel reconnection: \(error)")
                }
                nillableContinuation?.resume()
                nillableContinuation = nil
            }
            stores.dispatch(action)
        }
    }
}

private extension CardPresentPaymentService {
    @MainActor
    static func createCardReaderConnectionPublisher(stores: StoresManager) -> AnyPublisher<CardPresentPaymentCardReader?, Never> {
        let cardReadersConnectionPublisher: AnyPublisher<[CardReader], Never> = publisher(
            stores: stores,
            action: { .publishCardReaderConnections(onCompletion: $0) }
        )

        return cardReadersConnectionPublisher
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
    }

    @MainActor
    static func createUpdateStatePublisher(stores: StoresManager) -> AnyPublisher<CardReaderSoftwareUpdateState, Never> {
        publisher(
            stores: stores,
            action: { .observeCardReaderUpdateState(onCompletion: $0) }
        )
    }

    @MainActor
    static func createReconnectionStatusPublisher(stores: StoresManager) -> AnyPublisher<CardPresentPaymentReaderConnectionStatus, Never> {
        let reconnectionPublisher: AnyPublisher<CardReaderReconnectionState, Never> = publisher(
            stores: stores,
            action: { .observeCardReaderReconnectionState(onCompletion: $0) }
        )

        return reconnectionPublisher
            .compactMap { state -> CardPresentPaymentReaderConnectionStatus? in
                switch state {
                case .idle:
                    // Don't emit status for idle - other publishers handle connected/disconnected
                    return nil
                case .reconnecting(let reader):
                    let cardReader = CardPresentPaymentCardReader(
                        name: reader.name ?? reader.id,
                        batteryLevel: reader.batteryLevel,
                        softwareVersion: reader.softwareVersion
                    )
                    return .reconnecting(cardReader)
                case .succeeded(let reader):
                    let cardReader = CardPresentPaymentCardReader(
                        name: reader.name ?? reader.id,
                        batteryLevel: reader.batteryLevel,
                        softwareVersion: reader.softwareVersion
                    )
                    return .connected(cardReader)
                case .failed:
                    return .disconnected
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    @MainActor
    static func publisher<Output>(
        stores: StoresManager,
        action: (@escaping (AnyPublisher<Output, Never>) -> Void) -> CardPresentPaymentAction
    ) -> AnyPublisher<Output, Never> {
        var publisher: AnyPublisher<Output, Never>?

        // StoresManager dispatches these actions synchronously, and their handlers invoke the
        // callback inline. Keep the non-Sendable publisher in this main-actor call stack instead
        // of transferring it through an async continuation.
        stores.dispatch(action { publisher = $0 })

        guard let publisher else {
            DDLogError("CardPresentPaymentAction did not deliver its publisher synchronously")
            return Empty(completeImmediately: false).eraseToAnyPublisher()
        }
        return publisher
    }

    func createPreflightController(alertsPresenter: CardPresentPaymentsAlertPresenterAdaptor? = nil) -> CardPresentPaymentPreflightController<
        CardPresentPaymentTapToPayReaderConnectionAlertsProvider,
        CardPresentPaymentBluetoothReaderConnectionAlertsProvider,
        CardPresentPaymentsAlertPresenterAdaptor> {
            let alertProvider = CardPresentPaymentTapToPayReaderConnectionAlertsProvider()
            return CardPresentPaymentPreflightController(
                siteID: siteID,
                configuration: cardPresentPaymentsConfiguration,
                rootViewController: NullViewControllerPresenting(),
                alertsPresenter: alertsPresenter ?? paymentAlertsPresenterAdaptor,
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
