import Combine
import Foundation

/// A no-op replacement for the adapter wrapping the Stripe Terminal SDK
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

    /// The Publisher that emits the when when TTP Terms and Services are accepted
    public var tapToPayCardReaderAcceptToSEvents: AnyPublisher<Void, Never>
    = PassthroughSubject<Void, Never>().eraseToAnyPublisher()

    /// The Publisher that emits reconnection state changes for Bluetooth readers
    public var reconnectionEvents: AnyPublisher<CardReaderReconnectionState, Never>
    = CurrentValueSubject<CardReaderReconnectionState, Never>(.idle).eraseToAnyPublisher()

    public init() {}
    // MARK: - Commands

    public func checkSupport(for cardReaderType: CardReaderType,
                             configProvider: CardReaderConfigProvider,
                             discoveryMethod: CardReaderDiscoveryMethod,
                             minimumOperatingSystemVersionOverride: OperatingSystemVersion?) -> Bool {
        return false
    }

    /// Starts the service.
    /// That could imply, for example, that the reader discovery process starts
    public func start(_ configProvider: CardReaderConfigProvider, discoveryMethod: CardReaderDiscoveryMethod) throws {
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
    public func connect(_ reader: CardReader, options: CardReaderConnectionOptions?) -> AnyPublisher <CardReader, Error> {
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

    public func waitForInsertedCardToBeRemoved() -> Future<Void, Never> {
        Future() { promise in
            promise(.success(()))
        }
    }

    /// Clears and resets internal state.
    /// We need to call this method when switching accounts or stores
    public func clear() {
        // no-op
    }

    public func capturePayment(
        _ parameters: PaymentIntentParameters,
        beforePaymentConfirmation: @escaping (PaymentIntent) -> AnyPublisher<Void, Error>
    ) -> AnyPublisher<PaymentIntent, Error> {
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

    public func refundPayment(parameters: RefundParameters) -> AnyPublisher<String, Error> {
        return Future() { promise in
            promise(.failure(NSError.init(domain: "noopcardreader", code: 0, userInfo: nil)))
        }.eraseToAnyPublisher()
    }

    public func cancelRefund() -> AnyPublisher<Void, Error> {
        return Future() { promise in
            promise(.failure(NSError.init(domain: "noopcardreader", code: 0, userInfo: nil)))
        }.eraseToAnyPublisher()
    }

    public func retryActivePaymentIntent(
        beforePaymentConfirmation: @escaping (PaymentIntent) -> AnyPublisher<Void, Error>
    ) -> AnyPublisher<PaymentIntent, Error> {
        return Future() { promise in
            promise(.failure(NSError.init(domain: "noopcardreader", code: 0, userInfo: nil)))
        }.eraseToAnyPublisher()
    }

    /// Triggers a software update.
    ///
    /// To check the progress of the update, observe the softwareUpdateEvents publisher.
    public func installUpdate() -> Void {
        // no-op
    }

    /// Cancels an in-progress auto-reconnection attempt.
    public func cancelReconnection() -> Future<Void, Error> {
        return Future() { promise in
            promise(.success(()))
        }
    }
}
