import Combine
import StripeTerminal

/// The adapter wrapping the Stripe Terminal SDK
public final class StripeCardReaderService {
    private let tokenProvider: ConnectionTokenProvider

    private let discoveredReadersSubject = CurrentValueSubject<[CardReader], Error>([])
    private let connectedReaderSubject = PassthroughSubject<CardReader, Never>()
    private let connectionStatusSubject = CurrentValueSubject<ConnectionStatus, Never>(.notConnected)
    private let paymentStatusSubject = CurrentValueSubject<PaymentStatus, Never>(.notReady)
    private let readerSubject = PassthroughSubject<CardReaderEvent, Never>()

    public init(tokenProvider: ConnectionTokenProvider) {
        self.tokenProvider = tokenProvider
    }
}


// MARK: - CardReaderService conformance.
extension StripeCardReaderService: CardReaderService {

    // MARK: - CardReaderService conformance. Queries
    public var discoveredReaders: AnyPublisher<[CardReader], Error> {
        discoveredReadersSubject.eraseToAnyPublisher()
    }

    public var connectedReader: AnyPublisher<CardReader, Never> {
        connectedReaderSubject.eraseToAnyPublisher()
    }

    public var connectionStatus: AnyPublisher<ConnectionStatus, Never> {
        connectionStatusSubject.eraseToAnyPublisher()
    }

    /// The Publisher that emits the payment status
    public var paymentStatus: AnyPublisher<PaymentStatus, Never> {
        paymentStatusSubject.eraseToAnyPublisher()
    }

    /// The Publisher that emits reader events
    public var readerEvent: AnyPublisher<CardReaderEvent, Never> {
        readerSubject.eraseToAnyPublisher()
    }


    // MARK: - CardReaderService conformance. Commands
    public func connect(_ reader: CardReader) -> Future <Void, Error> {
        return Future() { promise in
            // This will be removed. We just want to execute this
            // Promise sometime in the future for now.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(Result.success(()))
            }
        }
    }
}
