import Combine
@testable import Hardware


/// Supports tests for CardPresentPaymentStore
final class MockCardReaderService: CardReaderService {
    var discoveredReaders: AnyPublisher<[Hardware.CardReader], Never> {
        CurrentValueSubject<[Hardware.CardReader], Never>([]).eraseToAnyPublisher()
    }

    var connectedReaders: AnyPublisher<[Hardware.CardReader], Never> {
        CurrentValueSubject<[Hardware.CardReader], Never>([]).eraseToAnyPublisher()
    }

    var serviceStatus: AnyPublisher<CardReaderServiceStatus, Never> {
        CurrentValueSubject<CardReaderServiceStatus, Never>(.ready).eraseToAnyPublisher()
    }

    var discoveryStatus: AnyPublisher<CardReaderServiceDiscoveryStatus, Never> {
        CurrentValueSubject<CardReaderServiceDiscoveryStatus, Never>(.idle).eraseToAnyPublisher()
    }

    var paymentStatus: AnyPublisher<PaymentStatus, Never> {
        CurrentValueSubject<PaymentStatus, Never>(.notReady).eraseToAnyPublisher()
    }

    var readerEvents: AnyPublisher<CardReaderEvent, Never> {
        PassthroughSubject<CardReaderEvent, Never>().eraseToAnyPublisher()
    }

    var didHitStart = false

    init() {

    }

    func start() {
        didHitStart = true
    }

    func cancelDiscovery() {
        
    }

    func connect(_ reader: Hardware.CardReader) -> Future<Void, Error> {
        Future() { promise in
            // To be implemented
        }
    }

    func disconnect(_ reader: Hardware.CardReader) -> Future<Void, Error> {
        Future() { promise in
            // This will be removed. We just want to pretend we are doing a roundtrip to the SDK for now.
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(Result.success(()))
            }
        }
    }

    func clear() { }

    func createPaymentIntent(_ parameters: PaymentIntentParameters) -> Future<PaymentIntent, Error> {
        Future() { promise in
            // To be implemented
        }
    }

    func collectPaymentMethod(_ intent: PaymentIntent) -> Future<PaymentIntent, Error> {
        Future() { promise in
            // To be implemented
        }
    }

    func processPaymentIntent(_ intent: PaymentIntent) -> Future<PaymentIntent, Error> {
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
