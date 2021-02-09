// Abstracts the integration with a Card Reader
public protocol CardReaderService {
    var delegate: CardReaderServiceDelegate? { get set }
    var connectedReader: CardReader? { get }
    var connectionStatus: ConnectionStatus { get }
    var paymentStatus: PaymentStatus { get }
}
