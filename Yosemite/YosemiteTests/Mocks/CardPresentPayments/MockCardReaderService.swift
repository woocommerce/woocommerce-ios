import Combine
@testable import Hardware


/// Supports tests for CardPresentPaymentStore
final class MockCardReaderService: CardReaderService {
    var discoveredReaders: AnyPublisher<[Hardware.CardReader], Never> {
        CurrentValueSubject<[Hardware.CardReader], Never>([]).eraseToAnyPublisher()
    }

    var connectedReaders: AnyPublisher<[Hardware.CardReader], Never> {
        connectedReadersSubject.eraseToAnyPublisher()
    }

    var serviceStatus: AnyPublisher<CardReaderServiceStatus, Never> {
        CurrentValueSubject<CardReaderServiceStatus, Never>(.ready).eraseToAnyPublisher()
    }

    var discoveryStatus: AnyPublisher<CardReaderServiceDiscoveryStatus, Never> {
        discoveryStatusSubject.eraseToAnyPublisher()
    }

    var paymentStatus: AnyPublisher<PaymentStatus, Never> {
        CurrentValueSubject<PaymentStatus, Never>(.notReady).eraseToAnyPublisher()
    }

    var readerEvents: AnyPublisher<CardReaderEvent, Never> {
        PassthroughSubject<CardReaderEvent, Never>().eraseToAnyPublisher()
    }

    /// Boolean flag Indicates that clients have called the start method
    var didHitStart = false

    /// Boolean flag Indicates that clients have called the cancel method
    var didHitCancel = false

    /// Boolean flag Indicates that clients have provided a CardReaderConfigProvider
    var didReceiveAConfigurationProvider = false

    private let connectedReadersSubject = CurrentValueSubject<[CardReader], Never>([])
    private let discoveryStatusSubject = CurrentValueSubject<CardReaderServiceDiscoveryStatus, Never>(.idle)


    init() {

    }

    func start(_ configProvider: CardReaderConfigProvider) {
        didHitStart = true
        didReceiveAConfigurationProvider = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in
            self?.discoveryStatusSubject.send(.discovering)
        }
    }

    func cancelDiscovery() {
        didHitCancel = true

        /// Delaying the effect of this method so that unit tests are actually async
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in
            self?.discoveryStatusSubject.send(.idle)
        }
    }

    func connect(_ reader: Hardware.CardReader) -> Future<Void, Error> {
        Future() { promise in
            /// Delaying the effect of this method so that unit tests are actually async
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in
                let connectedReader = MockCardReader.bbposChipper2XBT()
                promise(Result.success(()))
                self?.connectedReadersSubject.send([connectedReader])
            }
        }
    }

    func disconnect(_ reader: Hardware.CardReader) -> Future<Void, Error> {
        Future() { promise in
            // This will be removed. We just want to pretend we are doing a roundtrip to the SDK for now.
            /// Delaying the effect of this method so that unit tests are actually async
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(Result.success(()))
            }
        }
    }

    func clear() { }

    func createPaymentIntent(_ parameters: PaymentIntentParameters) -> Future<Void, Error> {
        Future() { promise in
            // To be implemented
        }
    }

    func collectPaymentMethod() -> Future<Void, Error> {
        Future() { promise in
            // To be implemented
        }
    }

    func processPayment() -> Future<PaymentIntent, Error> {
        Future() { promise in
            // To be implemented
        }
    }

    func cancelPaymentIntent(_ intent: PaymentIntent) -> Future<PaymentIntent, Error> {
        Future() { promise in
            // To be implemented
        }
    }
}
