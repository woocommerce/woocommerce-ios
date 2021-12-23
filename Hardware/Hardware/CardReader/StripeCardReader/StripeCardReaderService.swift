import Combine
import StripeTerminal
import CoreBluetooth

/// The adapter wrapping the Stripe Terminal SDK
public final class StripeCardReaderService: NSObject {

    private var discoveryCancellable: StripeTerminal.Cancelable?
    private var paymentCancellable: StripeTerminal.Cancelable?

    private var discoveredReadersSubject = CurrentValueSubject<[CardReader], Error>([])
    private let connectedReadersSubject = CurrentValueSubject<[CardReader], Never>([])
    private let discoveryStatusSubject = CurrentValueSubject<CardReaderServiceDiscoveryStatus, Never>(.idle)
    private let readerEventsSubject = PassthroughSubject<CardReaderEvent, Never>()
    private let softwareUpdateSubject = CurrentValueSubject<CardReaderSoftwareUpdateState, Never>(.none)

    /// Volatile, in-memory cache of discovered readers. It has to be cleared after we connect to a reader
    /// see
    ///  https://stripe.dev/stripe-terminal-ios/docs/Protocols/SCPDiscoveryDelegate.html#/c:objc(pl)SCPDiscoveryDelegate(im)terminal:didUpdateDiscoveredReaders:
    private let discoveredStripeReadersCache = StripeCardReaderDiscoveryCache()

    private var activePaymentIntent: StripeTerminal.PaymentIntent? = nil

    /// A lock to ensure that the service only initiates or cancels a discovery process at the same time
    private let discoveryLock = NSLock()

    private var readerLocationProvider: ReaderLocationProvider?

    /// Keeps track of whether a chip card needs to be removed
    private var timerCancellable: Cancellable?
    private var isChipCardInserted: Bool = false
}


// MARK: - CardReaderService conformance.
extension StripeCardReaderService: CardReaderService {

    // MARK: - CardReaderService conformance. Queries
    public var discoveredReaders: AnyPublisher<[CardReader], Error> {
        discoveredReadersSubject.eraseToAnyPublisher()
    }

    public var connectedReaders: AnyPublisher<[CardReader], Never> {
        connectedReadersSubject.eraseToAnyPublisher()
    }

    /// The Publisher that emits reader events
    public var readerEvents: AnyPublisher<CardReaderEvent, Never> {
        readerEventsSubject.eraseToAnyPublisher()
    }

    public var softwareUpdateEvents: AnyPublisher<CardReaderSoftwareUpdateState, Never> {
        softwareUpdateSubject.eraseToAnyPublisher()
    }

    // MARK: - CardReaderService conformance. Commands

    public func start(_ configProvider: CardReaderConfigProvider) throws {
        setConfigProvider(configProvider)

        Terminal.setLogListener {  message in
            // It seems stripe still tries to log messages when logLevel is .none,
            // so let's ignore those
            guard Terminal.shared.logLevel == .verbose else {
                return
            }
            DDLogDebug("💳 [StripeTerminal] \(message)")
        }
        Terminal.shared.logLevel = terminalLogLevel

        let config = DiscoveryConfiguration(discoveryMethod: .internet, locationId: "tml_ESCNWwpwlfv5JB", simulated: true)

//        let config = DiscoveryConfiguration(
//            discoveryMethod: .bluetoothScan,
//            simulated: shouldUseSimulatedCardReader
//        )

        // If we're using the simulated reader, we don't want to check for Bluetooth permissions
        // as the simulator won't have Bluetooth available.
        guard shouldUseSimulatedCardReader || CBCentralManager.authorization != .denied else {
            throw CardReaderServiceError.bluetoothDenied
        }

        Terminal.shared.delegate = self

        // We're now ready to start discovery, but first we'll check that we're not starting or canceling
        // another discovery process.
        // If we can't grab a lock quickly, let's fail rather than wait indefinitely
        guard discoveryLock.lock(before: Date().addingTimeInterval(1)) else {
            throw CardReaderServiceError.discovery(underlyingError: .busy)
        }
        // We only want to lock while we start the process to make sure another start or cancel doesn't collide.
        // The lock is released when we return from this method, when it will be OK to call cancel.
        defer { discoveryLock.unlock() }
        switchStatusToDiscovering()

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

            self?.switchStatusToFault(error: error)
        })
    }

    public func cancelDiscovery() -> Future <Void, Error> {
        Future { [weak self] promise in
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
            guard let self = self,
                  let discoveryCancellable = self.discoveryCancellable,
                  self.discoveryStatusSubject.value == .discovering else {
                return promise(.success(()))
            }

            // If all the previous checks are ok, and we are going to definitely cancel an existing
            // cancelable, then we attempt to grab a lock on the discovery process.
            // If it's not possible, then another start or cancel might be in progress, so we'll fail right away.
            guard self.discoveryLock.lock(before: Date().addingTimeInterval(1)) else {
                return promise(.failure(CardReaderServiceError.discovery(underlyingError: .busy)))
            }

            // The completion block for cancel, apparently, is called when
            // the SDK has not really transitioned to an idle state.
            // Clients might need to dispatch operations that rely on this completion block
            // to start a second operation on the card reader.
            // (for example, starting an operation after discovery has been cancelled)
            //
            discoveryCancellable.cancel { [discoveryLock = self.discoveryLock, weak self] error in
                // Horrible, terrible workaround.
                // And yet, it is the classic "dispatch to the next run cycle".
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [discoveryLock] in
                    guard let error = error else {
                        self?.switchStatusToIdle()
                        discoveryLock.unlock()
                        return promise(.success(()))
                    }

                    self?.internalError(error)
                    discoveryLock.unlock()
                    promise(.failure(error))
                }
            }
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
                self.waitForInsertedCardToBeRemoved(intent: intent)
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

            let cancelPaymentIntent = { [weak self] in
                Terminal.shared.cancelPaymentIntent(activePaymentIntent) { (intent, error) in
                    if let error = error {
                        let underlyingError = UnderlyingError(with: error)
                        promise(.failure(CardReaderServiceError.paymentCancellation(underlyingError: underlyingError)))
                    }

                    if let _ = intent {
                        self?.activePaymentIntent = nil
                        promise(.success(()))
                    }
                }
            }
            guard let paymentCancellable = self.paymentCancellable,
                  !paymentCancellable.completed else {
                return cancelPaymentIntent()
            }

            paymentCancellable.cancel({ [weak self] error in
                if error == nil {
                    self?.paymentCancellable = nil
                    cancelPaymentIntent()
                }
            })
        }
    }

    public func connect(_ reader: CardReader) -> AnyPublisher<CardReader, Error> {
        guard let stripeReader = self.discoveredStripeReadersCache.reader(matching: reader) as? Reader else {
            return Future() { promise in
                promise(.failure(CardReaderServiceError.connection()))
            }.eraseToAnyPublisher()
        }

        print("==== connecting to ")
        print(stripeReader)
        print("//// connecting to ")

        return getInternetConfiguration(stripeReader).flatMap { configuration in
            self.connect(stripeReader, configuration: configuration)
        }.eraseToAnyPublisher()

//        return getBluetoothConfiguration(stripeReader).flatMap { configuration in
//            self.connect(stripeReader, configuration: configuration)
//        }.eraseToAnyPublisher()
    }

    private func getInternetConfiguration(_ reader: StripeTerminal.Reader) -> Future<InternetConnectionConfiguration, Error> {
        return Future() { [weak self] promise in
            guard let self = self else {
                promise(.failure(CardReaderServiceError.connection()))
                return
            }

            promise(.success(InternetConnectionConfiguration(failIfInUse: true)))

//            // TODO - If we've recently connected to this reader, use the cached locationId from the
//            // Terminal SDK instead of making this fetch. See #5116 and #5087
//            self.readerLocationProvider?.fetchDefaultLocationID { (locationId, error) in
//                if let error = error {
//                    let underlyingError = UnderlyingError(with: error)
//                    return promise(.failure(CardReaderServiceError.connection(underlyingError: underlyingError)))
//                }
//
//                if let locationId = locationId {
//                    return promise(.success(InternetConnectionConfiguration(failIfInUse: true)))
//                }
//
//                promise(.failure(CardReaderServiceError.connection()))
//            }
        }
    }

    private func getBluetoothConfiguration(_ reader: StripeTerminal.Reader) -> Future<BluetoothConnectionConfiguration, Error> {
        return Future() { [weak self] promise in
            guard let self = self else {
                promise(.failure(CardReaderServiceError.connection()))
                return
            }

            // TODO - If we've recently connected to this reader, use the cached locationId from the
            // Terminal SDK instead of making this fetch. See #5116 and #5087
            self.readerLocationProvider?.fetchDefaultLocationID { result in
                switch result {
                case .success(let locationId):
                    return promise(.success(BluetoothConnectionConfiguration(locationId: locationId)))
                case .failure(let error):
                    let underlyingError = UnderlyingError(with: error)
                    return promise(.failure(CardReaderServiceError.connection(underlyingError: underlyingError)))
                }
            }
        }
    }

    public func connect(_ reader: StripeTerminal.Reader, configuration: InternetConnectionConfiguration) -> Future <CardReader, Error> {
        // Keep a copy of the battery level in case the connection fails due to low battery
        // If that happens, the reader object won't be accessible anymore, and we want to show
        // the current charge percentage if possible
        let batteryLevel = reader.batteryLevel?.doubleValue

        return Future { [weak self] promise in

            guard let self = self else {
                promise(.failure(CardReaderServiceError.connection()))
                return
            }

            Terminal.shared.connectInternetReader(reader, connectionConfig: configuration) { [weak self] (reader, error) in
                guard let self = self else {
                    promise(.failure(CardReaderServiceError.connection()))
                    return
                }

                // Clear cached readers, as per Stripe's documentation.
                self.discoveredStripeReadersCache.clear()

                if let error = error {
                    let underlyingError = UnderlyingError(with: error)
                    // Starting with StripeTerminal 2.0, required software updates happen transparently on connection
                    // Any error related to that will be reported here, but we don't want to treat it as a connection error
                    let serviceError: CardReaderServiceError = underlyingError.isSoftwareUpdateError ?
                        .softwareUpdate(underlyingError: underlyingError, batteryLevel: batteryLevel) :
                        .connection(underlyingError: underlyingError)
                    promise(.failure(serviceError))
                }

                if let reader = reader {
                    self.connectedReadersSubject.send([CardReader(reader: reader)])
                    self.switchStatusToIdle()
                    promise(.success(CardReader(reader: reader)))
                }
            }

//            Terminal.shared.connectBluetoothReader(reader, delegate: self, connectionConfig: configuration) { [weak self] (reader, error) in
//                guard let self = self else {
//                    promise(.failure(CardReaderServiceError.connection()))
//                    return
//                }
//
//                // Clear cached readers, as per Stripe's documentation.
//                self.discoveredStripeReadersCache.clear()
//
//                if let error = error {
//                    let underlyingError = UnderlyingError(with: error)
//                    // Starting with StripeTerminal 2.0, required software updates happen transparently on connection
//                    // Any error related to that will be reported here, but we don't want to treat it as a connection error
//                    let serviceError: CardReaderServiceError = underlyingError.isSoftwareUpdateError ?
//                        .softwareUpdate(underlyingError: underlyingError, batteryLevel: batteryLevel) :
//                        .connection(underlyingError: underlyingError)
//                    promise(.failure(serviceError))
//                }
//
//                if let reader = reader {
//                    self.connectedReadersSubject.send([CardReader(reader: reader)])
//                    self.switchStatusToIdle()
//                    promise(.success(CardReader(reader: reader)))
//                }
//            }
        }
    }

    public func connect(_ reader: StripeTerminal.Reader, configuration: BluetoothConnectionConfiguration) -> Future <CardReader, Error> {
        // Keep a copy of the battery level in case the connection fails due to low battery
        // If that happens, the reader object won't be accessible anymore, and we want to show
        // the current charge percentage if possible
        let batteryLevel = reader.batteryLevel?.doubleValue

        return Future { [weak self] promise in

            guard let self = self else {
                promise(.failure(CardReaderServiceError.connection()))
                return
            }

            Terminal.shared.connectBluetoothReader(reader, delegate: self, connectionConfig: configuration) { [weak self] (reader, error) in
                guard let self = self else {
                    promise(.failure(CardReaderServiceError.connection()))
                    return
                }

                // Clear cached readers, as per Stripe's documentation.
                self.discoveredStripeReadersCache.clear()

                if let error = error {
                    let underlyingError = UnderlyingError(with: error)
                    // Starting with StripeTerminal 2.0, required software updates happen transparently on connection
                    // Any error related to that will be reported here, but we don't want to treat it as a connection error
                    let serviceError: CardReaderServiceError = underlyingError.isSoftwareUpdateError ?
                        .softwareUpdate(underlyingError: underlyingError, batteryLevel: batteryLevel) :
                        .connection(underlyingError: underlyingError)
                    promise(.failure(serviceError))
                }

                if let reader = reader {
                    self.connectedReadersSubject.send([CardReader(reader: reader)])
                    self.switchStatusToIdle()
                    promise(.success(CardReader(reader: reader)))
                }
            }
        }
    }

    public func installUpdate() -> Void {
        Terminal.shared.installAvailableUpdate()
    }
}


// MARK: - Payment collection
private extension StripeCardReaderService {
    /// Returns the id of the connected reader, if any
    ///
    func readerIDForIntent() -> String? {
        connectedReadersSubject.value.first?.id
    }

    func readerModelForIntent() -> String? {
        connectedReadersSubject.value.first?.readerType.model
    }

    func createPaymentIntent(_ parameters: PaymentIntentParameters) -> Future<StripeTerminal.PaymentIntent, Error> {
        return Future() { [weak self] promise in
            // Shortcircuit if we have an inconsistent set of parameters
            guard let parameters = parameters.toStripe() else {
                promise(.failure(CardReaderServiceError.intentCreation()))
                return
            }

            /// Add the reader_ID to the request metadata so we can attribute this intent to the connected reader
            ///
            parameters.metadata?[Constants.readerIDMetadataKey] = self?.readerIDForIntent()
            parameters.metadata?[Constants.readerModelMetadataKey] = self?.readerModelForIntent()

            Terminal.shared.retrievePaymentIntent(clientSecret: "client_secret") { (intent, error) in
                if let error = error {
                    let underlyingError = UnderlyingError(with: error)
                    promise(.failure(CardReaderServiceError.intentCreation(underlyingError: underlyingError)))
                }

                self?.activePaymentIntent = intent

                if let intent = intent {
                    promise(.success(intent))
                }
            }

//            Terminal.shared.createPaymentIntent(parameters) { (intent, error) in
//                if let error = error {
//                    let underlyingError = UnderlyingError(with: error)
//                    promise(.failure(CardReaderServiceError.intentCreation(underlyingError: underlyingError)))
//                }
//
//                self?.activePaymentIntent = intent
//
//                if let intent = intent {
//                    promise(.success(intent))
//                }
//            }
        }
    }

    func collectPaymentMethod(intent: StripeTerminal.PaymentIntent) -> Future<StripeTerminal.PaymentIntent, Error> {
        return Future() { [weak self] promise in
            /// Collect Payment method returns a cancellable
            /// Because we are chaining promises, we need to retain a reference
            /// to this cancellable if we want to cancel 
            self?.paymentCancellable = Terminal.shared.collectPaymentMethod(intent) { (intent, error) in
                self?.paymentCancellable = nil

                if let error = error {
                    let underlyingError = UnderlyingError(with: error)
                    /// the completion block for collectPaymentMethod will be called
                    /// with error Canceled when collectPaymentMethod is canceled
                    /// https://stripe.dev/stripe-terminal-ios/docs/Classes/SCPTerminal.html#/c:objc(cs)SCPTerminal(im)collectPaymentMethod:delegate:completion:

                    if underlyingError != .commandCancelled {
                        DDLogError("💳 Error: collect payment method \(underlyingError)")
                        promise(.failure(CardReaderServiceError.paymentMethodCollection(underlyingError: underlyingError)))
                    }

                    if underlyingError == .commandCancelled {
                        DDLogWarn("💳 Warning: collect payment error cancelled. We actively ignore this error \(error)")
                    }

                }

                if let intent = intent {
                    promise(.success(intent))
                }
            }
        }
    }

    func waitForInsertedCardToBeRemoved(intent: StripeTerminal.PaymentIntent) -> Future<StripeTerminal.PaymentIntent, Error> {
        return Future() { [weak self] promise in
            guard let self = self else {
                return
            }

            // If there is no chip card inserted, it is ok to immediatedly return. The payment method may have been swipe or tap.
            if !self.isChipCardInserted {
                return promise(.success(intent))
            }

            self.timerCancellable = Timer.publish(every: 1, tolerance: 0.1, on: .main, in: .default)
                .autoconnect()
                .receive(on: DispatchQueue.main)
                .sink(receiveValue: { _ in
                    if !self.isChipCardInserted {
                        self.timerCancellable?.cancel()
                        return promise(.success(intent))
                    }
                })
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
        print("===== discovered readers ====")
        print(readers)
        print("///// discovered readers ====")
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
extension StripeCardReaderService: BluetoothReaderDelegate {
    public func reader(_ reader: Reader, didReportAvailableUpdate update: ReaderSoftwareUpdate) {
        softwareUpdateSubject.send(.available)
    }

    public func reader(_ reader: Reader, didStartInstallingUpdate update: ReaderSoftwareUpdate, cancelable: StripeTerminal.Cancelable?) {
        softwareUpdateSubject.send(.started(cancelable: cancelable.map(StripeCancelable.init(cancelable:))))
    }

    public func reader(_ reader: Reader, didReportReaderSoftwareUpdateProgress progress: Float) {
        softwareUpdateSubject.send(.installing(progress: progress))
    }

    public func reader(_ reader: Reader, didFinishInstallingUpdate update: ReaderSoftwareUpdate?, error: Error?) {
        if let error = error {
            softwareUpdateSubject.send(.failed(
                error: CardReaderServiceError.softwareUpdate(underlyingError: UnderlyingError(with: error),
                                                             batteryLevel: reader.batteryLevel?.doubleValue))
            )
            if let requiredDate = update?.requiredAt,
               requiredDate > Date() {
                softwareUpdateSubject.send(.available)
            } else {
                softwareUpdateSubject.send(.none)
            }
        } else {
            softwareUpdateSubject.send(.completed)
            connectedReadersSubject.send([CardReader(reader: reader)])
            softwareUpdateSubject.send(.none)
        }
    }

    /// This method is called by the Stripe Terminal SDK when it wants client apps
    /// to request users to tap / insert / swipe a card.
    public func reader(_ reader: Reader, didRequestReaderInput inputOptions: ReaderInputOptions = []) {
        sendReaderEvent(CardReaderEvent.make(readerInputOptions: inputOptions))
    }

    /// In this case the Stripe Terminal SDK wants us to present a string on screen
    public func reader(_ reader: Reader, didRequestReaderDisplayMessage displayMessage: ReaderDisplayMessage) {
        sendReaderEvent(CardReaderEvent.make(displayMessage: displayMessage))
    }

    /// Monitor and forward chip card insertion/removal events from the Terminal SDK
    /// So we can make sure inserted cards are removed during the collection of payment
    ///
    public func reader(_ reader: Reader, didReportReaderEvent event: ReaderEvent, info: [AnyHashable: Any]?) {
        switch event {
        case .cardInserted:
            isChipCardInserted = true
            sendReaderEvent(.cardInserted)
        case .cardRemoved:
            isChipCardInserted = false
            sendReaderEvent(.cardRemoved)
        default:
            break
        }
    }

    /// Receive changes in the reader battery level. Note that the SDK will call this delegate
    /// not more frequently than every 10 minutes and will not report battery level during payment collection.
    /// See `https://github.com/stripe/stripe-terminal-ios/issues/121#issuecomment-966589886`
    ///
    public func reader(_ reader: Reader, didReportBatteryLevel batteryLevel: Float, status: BatteryStatus, isCharging: Bool) {
        let connectedReaders = connectedReadersSubject.value

        guard let connectedReader = connectedReaders.first else {
            return
        }

        let connectedReaderWithUpdatedBatteryLevel = CardReader(
            serial: connectedReader.serial,
            vendorIdentifier: connectedReader.vendorIdentifier,
            name: connectedReader.name,
            status: connectedReader.status,
            softwareVersion: connectedReader.softwareVersion,
            batteryLevel: batteryLevel,
            readerType: connectedReader.readerType,
            locationId: connectedReader.locationId
        )

        connectedReadersSubject.send([connectedReaderWithUpdatedBatteryLevel])
    }
}

// MARK: - Terminal delegate
extension StripeCardReaderService: TerminalDelegate {
    public func terminal(_ terminal: Terminal, didReportUnexpectedReaderDisconnect reader: Reader) {
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
        readerLocationProvider = configProvider

        let tokenProvider = DefaultConnectionTokenProvider(provider: configProvider)

        if !Terminal.hasTokenProvider() {
            Terminal.setTokenProvider(tokenProvider)
        }
    }

    func resetDiscoveredReadersSubject(error: Error? = nil) {
        if let error = error {
            discoveredReadersSubject.send(completion: .failure(error))
        }
        discoveredReadersSubject.send(completion: .finished)
        discoveredReadersSubject = CurrentValueSubject<[CardReader], Error>([])
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

    func switchStatusToFault(error: Error) {
        updateDiscoveryStatus(to: .fault)
        resetDiscoveredReadersSubject(error: error)
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

// MARK: - Constants
//
private extension StripeCardReaderService {
    enum Constants {
        /// Used to decorate the payment intent with the reader ID so that we can correctly count
        /// the number of active readers for a store for a given time period. This key is also used
        /// by the Android app.
        ///
        static let readerIDMetadataKey = "reader_ID"
        static let readerModelMetadataKey = "reader_model"
    }
}

// MARK: - Debugging configuration
//
private extension StripeCardReaderService {
    var shouldUseSimulatedCardReader: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-simulate-stripe-card-reader")
        #else
        return false
        #endif
    }

    var terminalLogLevel: LogLevel {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-stripe-verbose-logging") {
            return .verbose
        } else {
            return .none
        }
        #else
        return .none
        #endif
    }
}
