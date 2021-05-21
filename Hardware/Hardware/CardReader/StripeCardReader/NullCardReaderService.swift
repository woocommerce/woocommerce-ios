import Combine
import Foundation

/// Supports tests for CardPresentPaymentStore
public final class NullCardReaderService: CardReaderService {
    public var discoveredReaders: AnyPublisher<[Hardware.CardReader], Error> {
        CurrentValueSubject<[Hardware.CardReader], Error>([]).eraseToAnyPublisher()
    }

    public var connectedReaders: AnyPublisher<[Hardware.CardReader], Never> {
        connectedReadersSubject.eraseToAnyPublisher()
    }

    public var serviceStatus: AnyPublisher<CardReaderServiceStatus, Never> {
        CurrentValueSubject<CardReaderServiceStatus, Never>(.ready).eraseToAnyPublisher()
    }

    public var discoveryStatus: AnyPublisher<CardReaderServiceDiscoveryStatus, Never> {
        discoveryStatusSubject.eraseToAnyPublisher()
    }

    public var paymentStatus: AnyPublisher<PaymentStatus, Never> {
        CurrentValueSubject<PaymentStatus, Never>(.notReady).eraseToAnyPublisher()
    }

    public var readerEvents: AnyPublisher<CardReaderEvent, Never> {
        PassthroughSubject<CardReaderEvent, Never>().eraseToAnyPublisher()
    }

    public var softwareUpdateEvents: AnyPublisher<Float, Never> {
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


    public init() {

    }

    public func start(_ configProvider: CardReaderConfigProvider) {
        didHitStart = true
        didReceiveAConfigurationProvider = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in
            self?.discoveryStatusSubject.send(.discovering)
        }
    }

    public func cancelDiscovery() -> Future<Void, Error> {
        didHitCancel = true

        /// Delaying the effect of this method so that unit tests are actually async
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in
                self?.discoveryStatusSubject.send(.idle)
                promise(.success(()))
            }
        }
    }

    public func connect(_ reader: Hardware.CardReader) -> Future<Hardware.CardReader, Error> {
        Future() { promise in
            /// Delaying the effect of this method so that unit tests are actually async
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in
                let connectedReader = MockCardReader.bbposChipper2XBT()
                promise(Result.success(connectedReader))
                self?.connectedReadersSubject.send([connectedReader])
            }
        }
    }

    public func disconnect() -> Future<Void, Error> {
        didHitDisconnect = true
        return Future() { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(Result.success(()))
            }
        }
    }

    public func clear() { }

    public func capturePayment(_ parameters: PaymentIntentParameters) -> AnyPublisher<PaymentIntent, Error> {
        Just(MockPaymentIntent.mock())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    public func cancelPaymentIntent() -> Future<Void, Error> {
        Future() { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self?.didTapCancelPayment = true
                promise(Result.success(()))
            }
        }
    }

    public func checkForUpdate() -> Future<CardReaderSoftwareUpdate, Error> {
        Future() { promise in
            // To be implemented
        }
    }

    public func installUpdate() -> AnyPublisher<Float, Error> {
        Empty<Float, Error>().eraseToAnyPublisher()
    }
}
