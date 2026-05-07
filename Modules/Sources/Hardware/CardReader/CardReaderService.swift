import Combine
import Foundation

/// Abstracts the integration with a Card Reader
public protocol CardReaderService {

    // MARK: - Queries
    /// The publisher that emits the list of discovered readers whenever the service discovers a new reader.
    var discoveredReaders: AnyPublisher<[CardReader], Error> { get }

    /// The Publisher that emits the connected readers
    var connectedReaders: AnyPublisher<[CardReader], Never> { get }

    /// The Publisher that emits reader events
    var readerEvents: AnyPublisher<CardReaderEvent, Never> { get }

    /// The Publisher that emits software update state changes
    var softwareUpdateEvents: AnyPublisher<CardReaderSoftwareUpdateState, Never> { get }

    /// The Publisher that emits when TTP Terms and Services are accepted
    var tapToPayCardReaderAcceptToSEvents: AnyPublisher<Void, Never> { get }

    /// The Publisher that emits reconnection state changes for Bluetooth readers
    var reconnectionEvents: AnyPublisher<CardReaderReconnectionState, Never> { get }

    // MARK: - Commands

    /// Checks for support of a given reader type and discovery method combination. Does not start discovery.
    ///
    func checkSupport(for cardReaderType: CardReaderType,
                      configProvider: CardReaderConfigProvider,
                      discoveryMethod: CardReaderDiscoveryMethod,
                      minimumOperatingSystemVersionOverride: OperatingSystemVersion?) -> Bool

    /// Starts the service.
    /// That could imply, for example, that the reader discovery process starts
    func start(_ configProvider: CardReaderConfigProvider, discoveryMethod: CardReaderDiscoveryMethod) throws

    /// Cancels the discovery process.
    func cancelDiscovery() -> Future<Void, Error>

    /// Connects to a card reader
    /// - Parameter reader: The card reader we want to connect to.
    func connect(_ reader: CardReader, options: CardReaderConnectionOptions?) -> AnyPublisher<CardReader, Error>

    /// Disconnects from the currently connected reader
    func disconnect() -> Future <Void, Error>

    /// Waits for the inserted card to be removed as a requirement after client-side processing.
    func waitForInsertedCardToBeRemoved() -> Future<Void, Never>

    /// Clears and resets internal state.
    /// We need to call this method when switching accounts or stores
    func clear()

    /// Captures a payment after collecting a payment method succeeds.
    /// The returned publisher will behave as a Future, eventually producing a single value and finishing, or failing.
    func capturePayment(_ parameters: PaymentIntentParameters) -> AnyPublisher<PaymentIntent, Error>

    /// Captures a payment, running a hook after payment method collection succeeds and before payment confirmation.
    /// The returned publisher will behave as a Future, eventually producing a single value and finishing, or failing.
    func capturePayment(_ parameters: PaymentIntentParameters,
                        beforePaymentConfirmation: @escaping (PaymentIntent) -> AnyPublisher<Void, Error>) -> AnyPublisher<PaymentIntent, Error>

    /// Retries the most recent payment intent attempted.
    /// The returned publisher will behave as a Future, eventually producing a single value and finishing, or failing.
    /// This action continues at the appropriate place in the `capturePayment` flow, but parameters cannot be changed.
    /// If the payment cannot be retried, an appropriate error will immediately return.
    func retryActivePaymentIntent() -> AnyPublisher<PaymentIntent, Error>

    /// Retries the most recent payment intent attempted, running a hook before payment confirmation.
    /// The returned publisher will behave as a Future, eventually producing a single value and finishing, or failing.
    func retryActivePaymentIntent(beforePaymentConfirmation: @escaping (PaymentIntent) -> AnyPublisher<Void, Error>) -> AnyPublisher<PaymentIntent, Error>

    /// Cancels a PaymentIntent
    func cancelPaymentIntent() -> Future<Void, Error>

    /// Refunds a payment
    func refundPayment(parameters: RefundParameters) -> AnyPublisher<String, Error>

    /// Cancels an in-flight refund
    func cancelRefund() -> AnyPublisher<Void, Error>

    /// Triggers a software update.
    ///
    /// To check the progress of the update, observe the softwareUpdateEvents publisher.
    func installUpdate() -> Void

    /// Cancels an in-progress auto-reconnection attempt.
    /// Use this when the user wants to manually connect a different reader
    /// or cancel the automatic reconnection process.
    func cancelReconnection() -> Future<Void, Error>
}

public extension CardReaderService {
    func capturePayment(_ parameters: PaymentIntentParameters,
                        beforePaymentConfirmation: @escaping (PaymentIntent) -> AnyPublisher<Void, Error>) -> AnyPublisher<PaymentIntent, Error> {
        capturePayment(parameters)
    }

    func retryActivePaymentIntent(beforePaymentConfirmation: @escaping (PaymentIntent) -> AnyPublisher<Void, Error>) -> AnyPublisher<PaymentIntent, Error> {
        retryActivePaymentIntent()
    }
}
