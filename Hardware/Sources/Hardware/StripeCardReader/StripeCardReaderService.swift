import Combine
import StripeTerminal

/// The adapter wrapping the Stripe Terminal SDK
public final class StripeCardReaderService {
    private let tokenProvider: ConnectionTokenProvider

    private let discoveredReadersSubject = CurrentValueSubject<[CardReader], Error>([])
    private let connectedReaderSubject = PassthroughSubject<CardReader, Never>()
    private let connectionStatusSubject = CurrentValueSubject<ConnectionStatus, Never>(.notConnected)

    private let paymentStatusSubject = CurrentValueSubject<PaymentStatus, Never>(.notReady)


    public init(tokenProvider: ConnectionTokenProvider) {
        self.tokenProvider = tokenProvider
    }
}


// MARK: - CardReaderService conformance
extension StripeCardReaderService: CardReaderService {
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
}
