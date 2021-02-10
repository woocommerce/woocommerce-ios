import Combine

/// Abstracts the integration with a Card Reader
public protocol CardReaderService {
    /// The publisher that emits the list of discovered readers whenever the service discovers a new reader.
    var discoveredReaders: AnyPublisher<[CardReader], Error> { get }

    /// The Publisher that emits the connected reader
    var connectedReader: AnyPublisher<CardReader, Never> { get }

    /// The Publisher that emits the connection status
    var connectionStatus: AnyPublisher<ConnectionStatus, Never> { get }

    /// The Publisher that emits the payment status
    var paymentStatus: AnyPublisher<PaymentStatus, Never> { get }

    /// The Publisher that emits reader events
    var readerEvent: AnyPublisher<CardReaderEvent, Never> { get }

    func connect(_ reader: CardReader) -> Future <Void, Error>
}
