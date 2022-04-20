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

    var readerEvents: AnyPublisher<CardReaderEvent, Never> {
        PassthroughSubject<CardReaderEvent, Never>().eraseToAnyPublisher()
    }

    var softwareUpdateEvents: AnyPublisher<CardReaderSoftwareUpdateState, Never> {
        CurrentValueSubject<CardReaderSoftwareUpdateState, Never>(.none).eraseToAnyPublisher()
    }

    /// Boolean flag Indicates that clients have called the start method
    var didHitStart = false

    /// Boolean flag Indicates that clients have called the cancel method
    var didHitCancel = false

    /// Boolean flag Indicates that clients have called the disconnect method
    var didHitDisconnect = false

    /// Boolean flag Indicates that clients have called the waitForInsertedCardToBeRemoved method
    var didHitWaitForInsertedCardToBeRemoved = false

    /// Boolean flag Indicates that clients have provided a CardReaderConfigProvider
    var didReceiveAConfigurationProvider = false

    /// Boolean flag Indicates that clients have called the cancel payment method
    var didTapCancelPayment = false

    /// Boolean flag indicates that checking for a reader software update should return an update
    var hasReaderUpdate = false

    /// Boolean flag indicates that checking for a reader software update should fail
    var shouldFailReaderUpdateCheck = false

    /// The publisher to return in `capturePayment`.
    private var capturePaymentPublisher: AnyPublisher<PaymentIntent, Error>?

    /// The future to return in `waitForInsertedCardToBeRemoved`.
    private var waitForInsertedCardToBeRemovedFuture: Future<Void, Error>?

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

    func connect(_ reader: Hardware.CardReader) -> AnyPublisher<CardReader, Error> {
        Future() { promise in
            /// Delaying the effect of this method so that unit tests are actually async
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {[weak self] in
                let connectedReader = MockCardReader.bbposChipper2XBT()
                promise(Result.success(connectedReader))
                self?.connectedReadersSubject.send([connectedReader])
            }
        }.eraseToAnyPublisher()
    }

    func disconnect() -> Future<Void, Error> {
        didHitDisconnect = true
        return Future() { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                promise(Result.success(()))
            }
        }
    }

    func waitForInsertedCardToBeRemoved() -> Future<Void, Error> {
        didHitWaitForInsertedCardToBeRemoved = true
        return waitForInsertedCardToBeRemovedFuture ??
        Future() { promise in
            DispatchQueue.main.async {
                promise(Result.success(()))
            }
        }
    }

    func clear() { }

    func capturePayment(_ parameters: PaymentIntentParameters) -> AnyPublisher<PaymentIntent, Error> {
        capturePaymentPublisher ??
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

    func refundPayment(parameters: RefundParameters) -> AnyPublisher<String, Error> {
        Just("success")
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func cancelRefund() -> AnyPublisher<Void, Error> {
        Just(())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func installUpdate() -> Void {
    }
}

extension MockCardReaderService {
    /// Set the return value if `capturePayment` is called.
    func whenCapturingPayment(thenReturn publisher: AnyPublisher<PaymentIntent, Error>) {
        capturePaymentPublisher = publisher
    }

    /// Set the return value if `waitForInsertedCardToBeRemoved` is called.
    func whenWaitForInsertedCardToBeRemoved(thenReturn future: Future<Void, Error>) {
        waitForInsertedCardToBeRemovedFuture = future
    }
}

private extension MockCardReaderService {
    enum MockErrors: Error {
        case readerUpdateCheckFailure
    }
}
