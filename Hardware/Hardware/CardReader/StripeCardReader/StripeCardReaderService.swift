import Combine
import StripeTerminal

/// The adapter wrapping the Stripe Terminal SDK
public final class StripeCardReaderService: NSObject {

    private var discoveryCancellable: StripeTerminal.Cancelable?
    private var paymentCancellable: StripeTerminal.Cancelable?

    private var discoveredReadersSubject = CurrentValueSubject<[CardReader], Never>([])
    private let connectedReadersSubject = CurrentValueSubject<[CardReader], Never>([])
    private let serviceStatusSubject = CurrentValueSubject<CardReaderServiceStatus, Never>(.ready)
    private let discoveryStatusSubject = CurrentValueSubject<CardReaderServiceDiscoveryStatus, Never>(.idle)
    private let paymentStatusSubject = CurrentValueSubject<PaymentStatus, Never>(.notReady)
    private let readerEventsSubject = PassthroughSubject<CardReaderEvent, Never>()
    private let softwareUpdateSubject = CurrentValueSubject<Float, Never>(0)

    /// Volatile, in-memory cache of discovered readers. It has to be cleared after we connect to a reader
    /// see
    ///  https://stripe.dev/stripe-terminal-ios/docs/Protocols/SCPDiscoveryDelegate.html#/c:objc(pl)SCPDiscoveryDelegate(im)terminal:didUpdateDiscoveredReaders:
    private let discoveredStripeReadersCache = StripeCardReaderDiscoveryCache()

    private var pendingSoftwareUpdate: ReaderSoftwareUpdate?

    private var activePaymentIntent: StripeTerminal.PaymentIntent? = nil
}


// MARK: - CardReaderService conformance.
extension StripeCardReaderService: CardReaderService {

    // MARK: - CardReaderService conformance. Queries
    public var discoveredReaders: AnyPublisher<[CardReader], Never> {
        discoveredReadersSubject.eraseToAnyPublisher()
    }

    public var connectedReaders: AnyPublisher<[CardReader], Never> {
        connectedReadersSubject.eraseToAnyPublisher()
    }

    public var serviceStatus: AnyPublisher<CardReaderServiceStatus, Never> {
        serviceStatusSubject.eraseToAnyPublisher()
    }

    public var discoveryStatus: AnyPublisher<CardReaderServiceDiscoveryStatus, Never> {
        discoveryStatusSubject.removeDuplicates().eraseToAnyPublisher()
    }

    /// The Publisher that emits the payment status
    public var paymentStatus: AnyPublisher<PaymentStatus, Never> {
        paymentStatusSubject.eraseToAnyPublisher()
    }

    /// The Publisher that emits reader events
    public var readerEvents: AnyPublisher<CardReaderEvent, Never> {
        readerEventsSubject.eraseToAnyPublisher()
    }

    public var softwareUpdateEvents: AnyPublisher<Float, Never> {
        softwareUpdateSubject.eraseToAnyPublisher()
    }

    // MARK: - CardReaderService conformance. Commands

    public func start(_ configProvider: CardReaderConfigProvider) {
        setConfigProvider(configProvider)

        let config = DiscoveryConfiguration(
            discoveryMethod: .bluetoothProximity,
            simulated: false
        )

        switchStatusToDiscovering()

        Terminal.shared.delegate = self

        /**
         * https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPTerminal.html#/c:objc(cs)SCPTerminal(im)discoverReaders:delegate:completion:
         *
         *Note that if discoverReaders is canceled, the completion block will be called with nil (rather than an SCPErrorCanceled error).
         */
        discoveryCancellable = Terminal.shared.discoverReaders(config, delegate: self, completion: { [weak self] error in
            guard let error = error else {
                self?.switchStatusToIdle()
                return
            }

            self?.internalError(error)
        })
    }

    public func cancelDiscovery() {
        /**
         *https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPTerminal.html#/c:objc(cs)SCPTerminal(im)discoverReaders:delegate:completion:
         *
         * The discovery process will stop on its own when the terminal
         * successfully connects to a reader, if the command is
         * canceled, or if a discovery error occurs.
         * So it does not hurt to check that we are actually in
         * discovering mode before attempting a cancellation
         *
         */
        guard discoveryStatusSubject.value == .discovering else {
            return
        }

        discoveryCancellable?.cancel { [weak self] error in
            guard let error = error else {
                self?.switchStatusToIdle()
                return
            }
            self?.internalError(error)
        }
    }

    public func disconnect() -> Future<Void, Error> {
        return Future() { promise in
            // Throw an error if the SDK has not been initialized.
            // This prevent a crash when logging out or switching stores before
            // the SDK has been initialized.
            // Why? https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPTerminal.html#/c:objc(cs)SCPTerminal(cpy)shared
            // `Before accessing the singleton for the first time, you must first call setTokenProvider: and setDelegate:.`
            guard Terminal.hasTokenProvider() else {
                promise(.failure(CardReaderServiceError.disconnection()))
                return
            }

            // Throw an error if we try to disconnect from nothing
            guard Terminal.shared.connectionStatus == .connected else {
                promise(.failure(CardReaderServiceError.disconnection()))
                return
            }

            /// If the disconnect succeeds, the completion block is called with nil.
            /// If the disconnect fails, the completion block is called with an error.
            /// https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPTerminal.html#/c:objc(cs)SCPTerminal(im)disconnectReader:
            Terminal.shared.disconnectReader { error in

                if let error = error {
                    let underlyingError = UnderlyingError(with: error)
                    promise(.failure(CardReaderServiceError.disconnection(underlyingError: underlyingError)))
                }

                if error == nil {
                    self.connectedReadersSubject.send([])
                    promise(.success(()))
                }
            }
        }
    }

    public func clear() {
        // Shortcircuit the SDK has not been initialized.
        // This prevent a crash when logging out or switching stores before
        // the SDK has been initialized.
        // Why? https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPTerminal.html#/c:objc(cs)SCPTerminal(cpy)shared
        // `Before accessing the singleton for the first time, you must first call setTokenProvider: and setDelegate:.`
        guard Terminal.hasTokenProvider() else {
            return
        }

        Terminal.shared.clearCachedCredentials()
    }

    public func capturePayment(_ parameters: PaymentIntentParameters) -> AnyPublisher<PaymentIntent, Error> {
        // The documentation for this protocol method promises that this will produce either
        // a single value or it will fail.
        // This isn't enforced by the type system, but it is guaranteed as long as all the
        // steps produce a Future.
        return createPaymentIntent(parameters)
            .flatMap { intent in
                self.collectPaymentMethod(intent: intent)
            }.flatMap { intent in
                self.processPayment(intent: intent)
            }.eraseToAnyPublisher()
    }

    public func cancelPaymentIntent() -> Future<Void, Error> {
        return Future() { [weak self] promise in
            guard let self = self,
                  let activePaymentIntent = self.activePaymentIntent else {
                promise(.failure(CardReaderServiceError.paymentCancellation()))
                return
            }

            self.paymentCancellable?.cancel({ error in
                if error == nil {
                    Terminal.shared.cancelPaymentIntent(activePaymentIntent) { (intent, error) in
                        if let error = error {
                            let underlyingError = UnderlyingError(with: error)
                            promise(.failure(CardReaderServiceError.paymentCancellation(underlyingError: underlyingError)))
                        }

                        if let _ = intent {
                            self.activePaymentIntent = nil
                            promise(.success(()))
                        }
                    }
                }
            })
        }
    }

    public func connect(_ reader: CardReader) -> Future <CardReader, Error> {
        return Future() { [weak self] promise in

            guard let self = self else {
                promise(.failure(CardReaderServiceError.connection()))
                return
            }

            // Find a cached reader that matches.
            // If this fails, that means that we are in an internal state that we do not expect.
            guard let stripeReader = self.discoveredStripeReadersCache.reader(matching: reader) as? Reader else {
                promise(.failure(CardReaderServiceError.connection()))
                return
            }

            Terminal.shared.connectReader(stripeReader) { [weak self] (reader, error) in
                guard let self = self else {
                    promise(.failure(CardReaderServiceError.connection()))
                    return
                }

                // Clear cached readers, as per Stripe's documentation.
                self.discoveredStripeReadersCache.clear()

                if let error = error {
                    let underlyingError = UnderlyingError(with: error)
                    promise(.failure(CardReaderServiceError.connection(underlyingError: underlyingError)))
                }

                if let reader = reader {
                    self.connectedReadersSubject.send([CardReader(reader: reader)])
                    self.switchStatusToIdle()
                    promise(.success(CardReader(reader: reader)))
                }
            }
        }
    }

    public func checkForUpdate() -> Future<CardReaderSoftwareUpdate, Error> {
        return Future() { promise in
            Terminal.shared.checkForUpdate { [weak self] (softwareUpdate, error) in
                guard let self = self else {
                    promise(.failure(CardReaderServiceError.softwareUpdate()))
                    return
                }

                if let error = error {
                    let underlyingError = UnderlyingError(with: error)
                    promise(.failure(CardReaderServiceError.softwareUpdate(underlyingError: underlyingError)))
                }

                if let softwareUpdate = softwareUpdate {
                    self.pendingSoftwareUpdate = softwareUpdate
                    let update = CardReaderSoftwareUpdate(update: softwareUpdate)
                    promise(.success(update))
                }
            }
        }
    }

    public func installUpdate() -> AnyPublisher<Float, Error> {
        // Before we do anything, make sure there is a pending software update
        guard let pendingUpdate = self.pendingSoftwareUpdate else {
            return Fail(outputType: Float.self, failure: CardReaderServiceError.softwareUpdate()).eraseToAnyPublisher()
        }

        // We create a future for the asynchronous call to installUpdate.
        // Since Combine doesn't offer enough options to combine values and completion events,
        // this publishes a true value when the update is completed.
        let installFuture = Future<Bool, Error> { promise in
            // If the update succeeds the completion block is called with nil
            // https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPTerminal.html#/c:objc(cs)SCPTerminal(im)installUpdate:delegate:completion:
            Terminal.shared.installUpdate(pendingUpdate, delegate: self) { [weak self] error in
                if error == nil {
                    self?.pendingSoftwareUpdate = nil
                    promise(.success(true))
                }

                if let error = error {
                    let underlyingError = UnderlyingError(with: error)
                    promise(.failure(CardReaderServiceError.softwareUpdate(underlyingError: underlyingError)))
                }
            }
        }

        // We want to combine the completion from the previous future with the progress events
        // coming from the delegate through softwareUpdateSubject.
        // To do this, we prepend an initial false value for `updateFinished`, and while that
        // is the latest value, we will republish progress events from softwareUpdateSubject.
        // Once we get a true value from the `installFuture` completion, we'll transform that
        // into an empty sequence so our publisher can finish.
        return installFuture
            .prepend(false)
            .map { [softwareUpdateSubject] updateFinished -> AnyPublisher<Float, Error> in
                if updateFinished {
                    return Empty()
                        .eraseToAnyPublisher()
                } else {
                    return softwareUpdateSubject
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}


// MARK: - Payment collection
private extension StripeCardReaderService {
    func createPaymentIntent(_ parameters: PaymentIntentParameters) -> Future<StripeTerminal.PaymentIntent, Error> {
        return Future() { [weak self] promise in
            // Shortcircuit if we have an inconsistent set of parameters
            guard let parameters = parameters.toStripe() else {
                promise(.failure(CardReaderServiceError.intentCreation()))
                return
            }

            Terminal.shared.createPaymentIntent(parameters) { (intent, error) in
                if let error = error {
                    let underlyingError = UnderlyingError(with: error)
                    promise(.failure(CardReaderServiceError.intentCreation(underlyingError: underlyingError)))
                }

                self?.activePaymentIntent = intent

                if let intent = intent {
                    promise(.success(intent))
                }
            }
        }
    }

    func collectPaymentMethod(intent: StripeTerminal.PaymentIntent) -> Future<StripeTerminal.PaymentIntent, Error> {
        return Future() { [weak self] promise in
            /// Collect Payment method returns a cancellable
            /// Because we are chainging promises, we need to retain a reference
            /// to this cancellable if we want to cancel 
            self?.paymentCancellable = Terminal.shared.collectPaymentMethod(intent, delegate: self) { (intent, error) in
                // Notify clients that the card, no matter it tapped or inserted, is not needed anymore.
                self?.sendReaderEvent(.cardRemoved)

                if let error = error {
                    let underlyingError = UnderlyingError(with: error)
                    promise(.failure(CardReaderServiceError.paymentMethodCollection(underlyingError: underlyingError)))
                }

                if let intent = intent {
                    promise(.success(intent))
                }
            }
        }
    }

    func processPayment(intent: StripeTerminal.PaymentIntent) -> Future<PaymentIntent, Error> {
        return Future() { [weak self] promise in
            Terminal.shared.processPayment(intent) { (intent, error) in
                if let error = error {
                    let underlyingError = UnderlyingError(with: error)
                    promise(.failure(CardReaderServiceError.paymentCapture(underlyingError: underlyingError)))
                }

                if let intent = intent {
                    promise(.success(PaymentIntent(intent: intent)))
                    self?.activePaymentIntent = nil
                }
            }
        }
    }
}


// MARK: - DiscoveryDelegate.
extension StripeCardReaderService: DiscoveryDelegate {
    public func terminal(_ terminal: Terminal, didUpdateDiscoveredReaders readers: [Reader]) {
        // Cache discovered readers. The cache needs to be cleared after we connect to a
        // specific reader
        discoveredStripeReadersCache.insert(readers)

        let wooReaders = readers.map {
            CardReader(reader: $0)
        }

        discoveredReadersSubject.send(wooReaders)
    }
}


// MARK: - ReaderDisplayDelegate.
extension StripeCardReaderService: ReaderDisplayDelegate {
    /// This method is called by the Stripe Terminal SDK when it wants client apps
    /// to request users to tap / insert / swipe a card.
    public func terminal(_ terminal: Terminal, didRequestReaderInput inputOptions: ReaderInputOptions = []) {
        sendReaderEvent(CardReaderEvent.make(readerInputOptions: inputOptions))
    }

    /// In this case the Stripe Terminal SDK wants us to present a string on screen
    public func terminal(_ terminal: Terminal, didRequestReaderDisplayMessage displayMessage: ReaderDisplayMessage) {
        sendReaderEvent(CardReaderEvent.make(displayMessage: displayMessage))
    }
}


// MARK: - Software update delegate.
extension StripeCardReaderService: ReaderSoftwareUpdateDelegate {
    public func terminal(_ terminal: Terminal, didReportReaderSoftwareUpdateProgress progress: Float) {
        softwareUpdateSubject.send(progress)
    }
}


// MARK: - Terminal delegate
extension StripeCardReaderService: TerminalDelegate {
    public func terminal(_ terminal: Terminal, didReportUnexpectedReaderDisconnect reader: Reader) {
        print("==== didReportUnexpectedReaderDisconnect ===")
        connectedReadersSubject.send([])
    }
}

// MARK: - Reader events
private extension StripeCardReaderService {
    func sendReaderEvent(_ event: CardReaderEvent) {
        readerEventsSubject.send(event)
    }
}

private extension StripeCardReaderService {
    private func setConfigProvider(_ configProvider: CardReaderConfigProvider) {
        let tokenProvider = DefaultConnectionTokenProvider(provider: configProvider)

        if !Terminal.hasTokenProvider() {
            Terminal.setTokenProvider(tokenProvider)
        }
    }

    func cancelReaderDiscovery() {
        discoveryCancellable?.cancel { [weak self] error in
            guard let self = self,
                  let error = error else {
                return
            }
            self.internalError(error)
        }
    }

    func resetDiscoveredReadersSubject() {
        discoveredReadersSubject.send(completion: .finished)
        discoveredReadersSubject = CurrentValueSubject<[CardReader], Never>([])
    }
}


// MARK: - Discovery status
private extension StripeCardReaderService {
    func switchStatusToIdle() {
        updateDiscoveryStatus(to: .idle)
        resetDiscoveredReadersSubject()
    }

    func switchStatusToDiscovering() {
        updateDiscoveryStatus(to: .discovering)
    }

    func switchStatusToFault() {
        updateDiscoveryStatus(to: .fault)
    }

    func updateDiscoveryStatus(to newStatus: CardReaderServiceDiscoveryStatus) {
        discoveryStatusSubject.send(newStatus)
    }
}


private extension StripeCardReaderService {
    func internalError(_ error: Error) {
        // Empty for now. Will be implemented later
    }
}
