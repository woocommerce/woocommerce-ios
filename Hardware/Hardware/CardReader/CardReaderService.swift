import Combine

/// Abstracts the integration with a Card Reader
public protocol CardReaderService {

    // MARK: - Queries
    /// The publisher that emits the list of discovered readers whenever the service discovers a new reader.
    var discoveredReaders: AnyPublisher<[CardReader], Error> { get }

    /// The Publisher that emits the connected readers
    var connectedReaders: AnyPublisher<[CardReader], Never> { get }

    /// The Publisher that emits the service status
    var serviceStatus: AnyPublisher<CardReaderServiceStatus, Never> { get }

    /// The Publisher that emits the service discovery status
    var discoveryStatus: AnyPublisher<CardReaderServiceDiscoveryStatus, Never> { get }

    /// The Publisher that emits the payment status
    var paymentStatus: AnyPublisher<PaymentStatus, Never> { get }

    /// The Publisher that emits reader events
    var readerEvents: AnyPublisher<CardReaderEvent, Never> { get }

    /// The Publisher that emits software update state changes
    var softwareUpdateEvents: AnyPublisher<CardReaderSoftwareUpdateState, Never> { get }

    // MARK: - Commands

    /// Starts the service.
    /// That could imply, for example, that the reader discovery process starts
    func start(_ configProvider: CardReaderConfigProvider) throws

    /// Cancels the discovery process.
    func cancelDiscovery() -> Future <Void, Error>

    /// Connects to a card reader
    /// - Parameter reader: The card reader we want to connect to.
    func connect(_ reader: CardReader) -> AnyPublisher <CardReader, Error>

    /// Disconnects from the currently connected reader
    func disconnect() -> Future <Void, Error>

    /// Clears and resets internal state.
    /// We need to call this method when switching accounts or stores
    func clear()

    /// Captures a payment after collecting a payment method succeeds.
    /// The returned publisher will behave as a Future, eventually producing a single value and finishing, or failing.
    func capturePayment(_ parameters: PaymentIntentParameters) -> AnyPublisher<PaymentIntent, Error>

    /// Cancels a PaymentIntent
    func cancelPaymentIntent() -> Future<Void, Error>

    /// Triggers a software update.
    ///
    /// To check the progress of the update, observe the softwareUpdateEvents publisher.
    func installUpdate() -> Void
}
