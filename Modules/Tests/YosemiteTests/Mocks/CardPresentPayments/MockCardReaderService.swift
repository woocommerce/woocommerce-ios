import Combine
import Foundation
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

    var tapToPayCardReaderAcceptToSEvents: AnyPublisher<Void, Never> {
        PassthroughSubject<Void, Never>().eraseToAnyPublisher()
    }

    var reconnectionEvents: AnyPublisher<CardReaderReconnectionState, Never> {
        reconnectionEventsSubject.eraseToAnyPublisher()
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

    /// DiscoveryMethod received on starting a payment
    var spyStartDiscoveryMethod: CardReaderDiscoveryMethod? = nil

    /// Boolean flag Indicates that clients have called the cancel payment method
    var didTapCancelPayment = false

    /// Boolean flag indicates that checking for a reader software update should return an update
    var hasReaderUpdate = false

    /// Boolean flag indicates that checking for a reader software update should fail
    var shouldFailReaderUpdateCheck = false

    /// The publisher to return in `capturePayment`.
    private var capturePaymentPublisher: AnyPublisher<PaymentIntent, Error>?


    var didCheckSupport = false
    var spyCheckSupportCardReaderType: CardReaderType? = nil
    var spyCheckSupportConfigProvider: CardReaderConfigProvider? = nil
    var spyCheckSupportDiscoveryMethod: CardReaderDiscoveryMethod? = nil
    var spyCheckSupportMinimumOperatingSystemVersionOverride: OperatingSystemVersion? = nil

    /// The future to return in `waitForInsertedCardToBeRemoved`.
    private var waitForInsertedCardToBeRemovedFuture: Future<Void, Never>?

    private let connectedReadersSubject = CurrentValueSubject<[CardReader], Never>([])
    private let discoveryStatusSubject = CurrentValueSubject<CardReaderServiceDiscoveryStatus, Never>(.idle)
    private let reconnectionEventsSubject = CurrentValueSubject<CardReaderReconnectionState, Never>(.idle)

    /// Boolean flag indicates that clients have called the cancelReconnection method
    var didHitCancelReconnection = false


    init() {

    }

    func checkSupport(for cardReaderType: Hardware.CardReaderType,
                      configProvider: Hardware.CardReaderConfigProvider,
                      discoveryMethod: Hardware.CardReaderDiscoveryMethod,
                      minimumOperatingSystemVersionOverride: OperatingSystemVersion?) -> Bool {
        didCheckSupport = true
        spyCheckSupportCardReaderType = cardReaderType
        spyCheckSupportConfigProvider = configProvider
        spyCheckSupportDiscoveryMethod = discoveryMethod
        spyCheckSupportMinimumOperatingSystemVersionOverride = minimumOperatingSystemVersionOverride

        return true
    }

    func start(_ configProvider: Hardware.CardReaderConfigProvider, discoveryMethod: Hardware.CardReaderDiscoveryMethod) throws {
        didHitStart = true
        didReceiveAConfigurationProvider = true
        spyStartDiscoveryMethod = discoveryMethod

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {[weak self] in
            self?.discoveryStatusSubject.send(.discovering)
        }
    }

    func cancelDiscovery() -> Future<Void, Error> {
        didHitCancel = true

        /// Delaying the effect of this method so that unit tests are actually async
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {[weak self] in
                self?.discoveryStatusSubject.send(.idle)
                promise(.success(()))
            }
        }
    }

    func connect(_ reader: Hardware.CardReader, options: Hardware.CardReaderConnectionOptions?) -> AnyPublisher<CardReader, Error> {
        Future() { promise in
            /// Delaying the effect of this method so that unit tests are actually async
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {[weak self] in
                let connectedReader = MockCardReader.bbposChipper2XBT()
                promise(Result.success(connectedReader))
                self?.connectedReadersSubject.send([connectedReader])
            }
        }.eraseToAnyPublisher()
    }

    func disconnect() -> Future<Void, Error> {
        didHitDisconnect = true
        return Future() { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                promise(Result.success(()))
            }
        }
    }

    func waitForInsertedCardToBeRemoved() -> Future<Void, Never> {
        didHitWaitForInsertedCardToBeRemoved = true
        return waitForInsertedCardToBeRemovedFuture ??
        Future() { promise in
            DispatchQueue.main.async {
                promise(.success(()))
            }
        }
    }

    func clear() { }

    func capturePayment(_ parameters: PaymentIntentParameters) -> AnyPublisher<PaymentIntent, Error> {
        capturePaymentPublisher ??
        Just(.fake())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func capturePayment(_ parameters: PaymentIntentParameters,
                        beforePaymentConfirmation: @escaping (PaymentIntent) -> AnyPublisher<Void, Error>) -> AnyPublisher<PaymentIntent, Error> {
        capturePayment(parameters)
            .flatMap { intent in
                beforePaymentConfirmation(intent)
                    .map { intent }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func retryActivePaymentIntent() -> AnyPublisher<Hardware.PaymentIntent, Error> {
        Just(.fake())
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }

    func retryActivePaymentIntent(
        beforePaymentConfirmation: @escaping (PaymentIntent) -> AnyPublisher<Void, Error>
    ) -> AnyPublisher<Hardware.PaymentIntent, Error> {
        retryActivePaymentIntent()
            .flatMap { intent in
                beforePaymentConfirmation(intent)
                    .map { intent }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func cancelPaymentIntent() -> Future<Void, Error> {
        Future() { [weak self] promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
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

    func cancelReconnection() -> Future<Void, Error> {
        didHitCancelReconnection = true
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                promise(.success(()))
            }
        }
    }
}

extension MockCardReaderService {
    /// Set the return value if `capturePayment` is called.
    func whenCapturingPayment(thenReturn publisher: AnyPublisher<PaymentIntent, Error>) {
        capturePaymentPublisher = publisher
    }

    /// Set the return value if `waitForInsertedCardToBeRemoved` is called.
    func whenWaitForInsertedCardToBeRemoved(thenReturn future: Future<Void, Never>) {
        waitForInsertedCardToBeRemovedFuture = future
    }

    func simulateReconnectionStarted(reader: CardReader) {
        reconnectionEventsSubject.send(.reconnecting(reader: reader))
    }

    func simulateReconnectionSucceeded(reader: CardReader) {
        reconnectionEventsSubject.send(.succeeded(reader: reader))
        connectedReadersSubject.send([reader])
        reconnectionEventsSubject.send(.idle)
    }

    func simulateReconnectionFailed(reader: CardReader) {
        reconnectionEventsSubject.send(.failed(reader: reader))
        connectedReadersSubject.send([])
        reconnectionEventsSubject.send(.idle)
    }
}

private extension MockCardReaderService {
    enum MockErrors: Error {
        case readerUpdateCheckFailure
    }
}
