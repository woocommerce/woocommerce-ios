import Combine
@testable import Hardware


/// Supports tests for CardPresentPaymentStore
final class MockCardReaderService: CardReaderService {
    var discoveredReaders: AnyPublisher<[Hardware.CardReader], Error> {
        CurrentValueSubject<[Hardware.CardReader], Error>([]).eraseToAnyPublisher()
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

    var softwareUpdateEvents: AnyPublisher<Float, Never> {
        CurrentValueSubject<Float, Never>(0).eraseToAnyPublisher()
    }

    /// Boolean flag Indicates that clients have called the start method
    var didHitStart = false

    /// Boolean flag Indicates that clients have called the cancel method
    var didHitCancel = false

    /// Boolean flag Indicates that clients have called the disconnect method
    var didHitDisconnect = false

    /// Boolean flag Indicates that clients have provided a CardReaderConfigProvider
    var didReceiveAConfigurationProvider = false

    /// Boolean flag Indicates that clients have called the cancel payment method
    var didTapCancelPayment = false

    private let connectedReadersSubject = CurrentValueSubject<[CardReader], Never>([])
    private let discoveryStatusSubject = CurrentValueSubject<CardReaderServiceDiscoveryStatus, Never>(.idle)


    init() {

    }

    func start(_ configProvider: CardReaderConfigProvider) throws {
        didHitStart = true
        didReceiveAConfigurationProvider = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in
            self?.discoveryStatusSubject.send(.discovering)
        }
    }

    func cancelDiscovery() -> Future<Void, Error> {
        didHitCancel = true

        /// Delaying the effect of this method so that unit tests are actually async
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in
                self?.discoveryStatusSubject.send(.idle)
                promise(.success(()))
            }
        }
    }

    func connect(_ reader: Hardware.CardReader) -> Future<Hardware.CardReader, Error> {
        Future() { promise in
            /// Delaying the effect of this method so that unit tests are actually async
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in
                let connectedReader = MockCardReader.bbposChipper2XBT()
                promise(Result.success(connectedReader))
                self?.connectedReadersSubject.send([connectedReader])
            }
        }
    }

    func disconnect() -> Future<Void, Error> {
        didHitDisconnect = true
        return Future() { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(Result.success(()))
            }
        }
    }

    func clear() { }

    func capturePayment(_ parameters: PaymentIntentParameters) -> AnyPublisher<PaymentIntent, Error> {
        Just(MockPaymentIntent.mock())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func cancelPaymentIntent() -> Future<Void, Error> {
        Future() { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self?.didTapCancelPayment = true
                promise(Result.success(()))
            }
        }
    }

    func checkForUpdate() -> Future<CardReaderSoftwareUpdate, Error> {
        Future() { promise in
            // To be implemented
        }
    }

    func installUpdate() -> AnyPublisher<Float, Error> {
        Empty<Float, Error>().eraseToAnyPublisher()
    }
}
