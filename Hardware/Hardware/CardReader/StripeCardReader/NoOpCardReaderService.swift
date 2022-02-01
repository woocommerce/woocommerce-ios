import Combine
/// The adapter wrapping the Stripe Terminal SDK
public struct NoOpCardReaderService: CardReaderService {
    // MARK: - Queries
    /// The publisher that emits the list of discovered readers whenever the service discovers a new reader.
    public var discoveredReaders: AnyPublisher<[CardReader], Error> = CurrentValueSubject<[CardReader], Error>([]).eraseToAnyPublisher()

    /// The Publisher that emits the connected readers
    public var connectedReaders: AnyPublisher<[CardReader], Never> = CurrentValueSubject<[CardReader], Never>([]).eraseToAnyPublisher()

    /// The Publisher that emits reader events
    public var readerEvents: AnyPublisher<CardReaderEvent, Never> = PassthroughSubject<CardReaderEvent, Never>().eraseToAnyPublisher()

    /// The Publisher that emits software update state changes
    public var softwareUpdateEvents: AnyPublisher<CardReaderSoftwareUpdateState, Never>
    = CurrentValueSubject<CardReaderSoftwareUpdateState, Never>(.none).eraseToAnyPublisher()

    public init() {}
    // MARK: - Commands

    /// Starts the service.
    /// That could imply, for example, that the reader discovery process starts
    public func start(_ configProvider: CardReaderConfigProvider) throws {
        // no-op
    }

    /// Cancels the discovery process.
    public func cancelDiscovery() -> Future <Void, Error> {
        return Future() { promise in
            promise(.failure(NSError.init(domain: "noopcardreader", code: 0, userInfo: nil)))
        }
    }

    /// Connects to a card reader
    /// - Parameter reader: The card reader we want to connect to.
    public func connect(_ reader: CardReader) -> AnyPublisher <CardReader, Error> {
        return Future() { promise in
            promise(.failure(NSError.init(domain: "noopcardreader", code: 0, userInfo: nil)))
        }.eraseToAnyPublisher()
    }

    /// Disconnects from the currently connected reader
    public func disconnect() -> Future <Void, Error> {
        return Future() { promise in
            promise(.failure(NSError.init(domain: "noopcardreader", code: 0, userInfo: nil)))
        }
    }

    /// Clears and resets internal state.
    /// We need to call this method when switching accounts or stores
    public func clear() {
        // no-op
    }

    /// Captures a payment after collecting a payment method succeeds.
    /// The returned publisher will behave as a Future, eventually producing a single value and finishing, or failing.
    public func capturePayment(_ parameters: PaymentIntentParameters) -> AnyPublisher<PaymentIntent, Error> {
        return Future() { promise in
            promise(.failure(NSError.init(domain: "noopcardreader", code: 0, userInfo: nil)))
        }.eraseToAnyPublisher()
    }

    /// Cancels a PaymentIntent
    public func cancelPaymentIntent() -> Future<Void, Error> {
        return Future() { promise in
            promise(.failure(NSError.init(domain: "noopcardreader", code: 0, userInfo: nil)))
        }
    }

    /// Triggers a software update.
    ///
    /// To check the progress of the update, observe the softwareUpdateEvents publisher.
    public func installUpdate() -> Void {
        // no-op
    }
}
