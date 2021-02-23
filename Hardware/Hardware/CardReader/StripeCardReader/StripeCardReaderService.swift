import Combine
import StripeTerminal

/// The adapter wrapping the Stripe Terminal SDK
public final class StripeCardReaderService: NSObject {

    private var discoveryCancellable: StripeTerminal.Cancelable?

    private let discoveredReadersSubject = CurrentValueSubject<[CardReader], Never>([])
    private let connectedReadersSubject = CurrentValueSubject<[CardReader], Never>([])
    private let serviceStatusSubject = CurrentValueSubject<CardReaderServiceStatus, Never>(.ready)
    private let discoveryStatusSubject = CurrentValueSubject<CardReaderServiceDiscoveryStatus, Never>(.idle)
    private let paymentStatusSubject = CurrentValueSubject<PaymentStatus, Never>(.notReady)
    private let readerEventsSubject = PassthroughSubject<CardReaderEvent, Never>()

    public init(tokenProvider: ConnectionTokenProvider) {
        // Per Stripe SDK's instructions, the first we need to do is set the token provider, before calling `shared`
        // If we don't, an assertion will 💥
        // We can only set the token once
        if !Terminal.hasTokenProvider() {
            Terminal.setTokenProvider(tokenProvider)
        }
    }
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
        discoveryStatusSubject.eraseToAnyPublisher()
    }

    /// The Publisher that emits the payment status
    public var paymentStatus: AnyPublisher<PaymentStatus, Never> {
        paymentStatusSubject.eraseToAnyPublisher()
    }

    /// The Publisher that emits reader events
    public var readerEvents: AnyPublisher<CardReaderEvent, Never> {
        readerEventsSubject.eraseToAnyPublisher()
    }


    // MARK: - CardReaderService conformance. Commands

    public func start() {
        // This is enough code to pass a unit test.
        // The final version of this method would be completely different.
        // But for now, we want to start the discovery process using the
        // simulate reader included in the Stripe Terminal SDK
        // https://stripe.com/docs/terminal/integration?country=CA&platform=ios&reader=p400#dev-test

        // Attack the test terminal, provided by the SDK
        let config = DiscoveryConfiguration(
            discoveryMethod: .internet,
            simulated: true
        )

        // Cancel a previous discovery process if it is still in flight
        cancelReaderDiscovery()
        // Enough code to pass a test
        discoveryCancellable = Terminal.shared.discoverReaders(config, delegate: self, completion: { error in
            if let error = error {
                print("discoverReaders failed: \(error)")
            } else {
                print("discoverReaders succeeded")
            }
        })
    }

    public func cancelDiscovery() {
        // Bouncing to a private method just in case we need to do something else
        // If we realize we don't, there is no point in having two methods doing the same
        cancelReaderDiscovery()
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
        Terminal.shared.clearCachedCredentials()
    }

    public func createPaymentIntent(_ parameters: PaymentIntentParameters) -> Future<PaymentIntent, Error> {
        return Future() { promise in
            // Attack the Stripe SDK and create a PaymentIntent.
            // To be implemented
        }
    }

    public func collectPaymentMethod(_ intent: PaymentIntent) -> Future<PaymentIntent, Error> {
        return Future() { promise in
            // Attack the Stripe SDK to collect a payment method.
            // To be implemented
        }
    }

    public func processPaymentIntent(_ intent: PaymentIntent) -> Future<PaymentIntent, Error> {
        return Future() { promise in
            // Attack the Stripe SDK and process a PaymentIntent.
            // To be implemented
        }
    }

    public func cancelPaymentIntent(_ intent: PaymentIntent) -> Future<PaymentIntent, Error> {
        return Future() { promise in
            // Attack the Stripe SDK and cancel a PaymentIntent.
            // To be implemented
        }
    }

    public func connect(_ reader: CardReader) -> Future <Void, Error> {
        return Future() { promise in

            guard let stripeReader = reader.toStripe() else {
                promise(Result.failure(CardReaderServiceError.connection))
                return
            }

            Terminal.shared.connectReader(stripeReader) { [weak self] (reader, error) in
                guard let self = self else {
                    return
                }

                if let _ = error {
                    promise(Result.failure(CardReaderServiceError.connection))
                }

                if let reader = reader {
                    self.connectedReadersSubject.send([CardReader(reader: reader)])
                    promise(Result.success(()))
                }
            }
        }
    }
}



// MARK: - DiscoveryDelegate.
extension StripeCardReaderService: DiscoveryDelegate {
    /// Enough code to pass the test
    public func terminal(_ terminal: Terminal, didUpdateDiscoveredReaders readers: [Reader]) {
        let wooReaders = readers.map {
            CardReader(reader: $0)
        }

        discoveredReadersSubject.send(wooReaders)
    }
}


private extension StripeCardReaderService {
    func cancelReaderDiscovery() {
        discoveryCancellable?.cancel { [weak self] error in
            guard let self = self,
                  let error = error else {
                return
            }

            self.handleError(error)
        }
    }

    func resetDiscoveredReadersSubject() {
        discoveredReadersSubject.send([])
    }
}


private extension StripeCardReaderService {
    func handleError(_ error: Error) {
        // Empty for now. Will be implemented later
    }
}


private enum CardReaderServiceError: Error {
    case discovery
    case connection
}
