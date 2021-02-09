import StripeTerminal

/// The adapter wrapping the Stripe Terminal SDK
public final class StripeCardReaderService: CardReaderService {
    public var delegate: CardReaderServiceDelegate? = nil

    public let connectedReader: CardReader? = nil

    public let connectionStatus: ConnectionStatus = .notConnected

    public let paymentStatus: PaymentStatus = .notReady

    private let tokenProvider: ConnectionTokenProvider

    public init(tokenProvider: ConnectionTokenProvider) {
        self.tokenProvider = tokenProvider
    }
}
