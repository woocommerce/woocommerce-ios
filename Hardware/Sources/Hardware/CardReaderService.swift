/// Abstracts the integration with a Card Reader
public protocol CardReaderService {
    /// The service delegate.
    var delegate: CardReaderServiceDelegate? { get set }

    /// Returns the connected reader, or nil if no reader is connected
    var connectedReader: CardReader? { get }

    /// The CardReaderService's connection status
    var connectionStatus: ConnectionStatus { get }

    /// The CardReaderService's current payment status
    var paymentStatus: PaymentStatus { get }
}
