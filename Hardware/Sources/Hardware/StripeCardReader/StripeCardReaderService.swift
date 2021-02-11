import Combine
import StripeTerminal

/// The adapter wrapping the Stripe Terminal SDK.
/// This is the boundary between our code and the Stripe Terminal SDK.
/// This class is final for now. Depending on how testable it is, we might want to
/// provide a subclass only for tests. In theory, the Stripe Terminal SDK provides
/// a simulates reader that we can attack in unit tests:
/// https://stripe.com/docs/terminal/integration?country=CA&platform=ios&reader=p400#dev-test
///
/// It needs to extend NSObject in order to conform to DiscoveryDelegate.
///
public final class StripeCardReaderService: NSObject {
    private let tokenProvider: ConnectionTokenProvider

    private let discoveredReadersSubject = CurrentValueSubject<[CardReader], Error>([])
    private let connectedReaderSubject = PassthroughSubject<CardReader, Never>()
    private let connectionStatusSubject = CurrentValueSubject<ConnectionStatus, Never>(.notConnected)
    private let paymentStatusSubject = CurrentValueSubject<PaymentStatus, Never>(.notReady)
    private let readerSubject = PassthroughSubject<CardReaderEvent, Never>()

    private var discoveryCancellable: StripeTerminal.Cancelable?

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

    public func start() {
        // This is enough code to pass a unit test.
        // The final version of this method would be completely different.
        // But for now, we want to start the discovery process using the
        // simulate reader included in the Stripe Terminal SDK
        // https://stripe.com/docs/terminal/integration?country=CA&platform=ios&reader=p400#dev-test

        // Per Stripe SDK's instructions, the first we need to do is set the token provider, before calling `shared`
        // If we don't, an assertion will 💥

        Terminal.setTokenProvider(self.tokenProvider)

        // Attack the test terminal, provided by the SDK
        let config = DiscoveryConfiguration(
            discoveryMethod: .internet,
            simulated: true
        )

        // Enough code to pass a test
        discoveryCancellable = Terminal.shared.discoverReaders(config, delegate: self, completion: { error in
            if let error = error {
                print("discoverReaders failed: \(error)")
            } else {
                print("discoverReaders succeeded")
            }
        })
    }

    public func disconnect(_ reader: CardReader) -> Future<Void, Error> {
        return Future() { promise in
            // This will be removed. We just want to pretend we are doing a roundtrip to the SDK for now.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(Result.success(()))
            }
        }
    }

    public func clear() {
        // 🧹
    }

    public func createPaymentIntent(_ parameters: PaymentIntentParameters) -> Future<PaymentIntent, Error> {
        return Future() { promise in
            // This will be removed. We just want to pretend we are doing a roundtrip to the SDK for now.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(Result.success(PaymentIntent()))
            }
        }
    }

    public func collectPaymentMethod(_ intent: PaymentIntent) -> Future<PaymentIntent, Error> {
        return Future() { promise in
            // This will be removed. We just want to pretend we are doing a roundtrip to the SDK for now.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(Result.success(PaymentIntent()))
            }
        }
    }

    public func processPaymentIntent(_ intent: PaymentIntent) -> Future<PaymentIntent, Error> {
        return Future() { promise in
            // This will be removed. We just want to pretend we are doing a roundtrip to the SDK for now.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(Result.success(PaymentIntent()))
            }
        }
    }

    public func cancelPaymentIntent(_ intent: PaymentIntent) -> Future<PaymentIntent, Error> {
        return Future() { promise in
            // This will be removed. We just want to pretend we are doing a roundtrip to the SDK for now.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(Result.success(PaymentIntent()))
            }
        }
    }

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


// MARK: - DiscoveryDelegate.
extension StripeCardReaderService: DiscoveryDelegate {
    /// Enough code to pass the test
    public func terminal(_ terminal: Terminal, didUpdateDiscoveredReaders readers: [Reader]) {
        // Map Stripe's Reader to Hardware.CardReader
        let wooReaders = readers.map { _ in
            CardReader()
        }

        discoveredReadersSubject.send(wooReaders)
    }
}
