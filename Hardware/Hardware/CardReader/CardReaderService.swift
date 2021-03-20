import Combine

/// Abstracts the integration with a Card Reader
public protocol CardReaderService {

    // MARK: - Queries
    /// The publisher that emits the list of discovered readers whenever the service discovers a new reader.
    var discoveredReaders: AnyPublisher<[CardReader], Never> { get }

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

    // MARK: - Commands

    /// Starts the service.
    /// That could imply, for example, that the reader discovery process starts
    func start(_ configProvider: CardReaderConfigProvider)

    /// Cancels the discovery process.
    func cancelDiscovery()

    /// Connects to a card reader
    /// - Parameter reader: The card reader we want to connect to.
    func connect(_ reader: CardReader) -> Future <Void, Error>

    /// Disconnects a card reader
    /// - Parameter reader: The card reader we want to connect to.
    func disconnect(_ reader: CardReader) -> Future <Void, Error>

    /// Clears and resets internal state.
    /// We need to call this method when switching accounts or stores
    func clear()

    /// Creates a PaymentIntent
    /// - Parameter parameters: the intent's parameters
    func createPaymentIntent(_ parameters: PaymentIntentParameters) -> Future <Void, Error>

    /// Collects a payment method.
    func collectPaymentMethod() -> Future<Void, Error>

    /// Captures a payment after collecting a payment method succeeds.
    /// In the success case, it returns the PaymentIntent id
    func processPayment() -> Future<String, Error>


    /// Cancels a a PaymentIntent
    func cancelPaymentIntent() -> Future<Void, Error>
}
