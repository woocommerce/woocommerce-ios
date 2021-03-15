// MARK: - CardPresentPaymentAction: Defines all of the Actions supported by the CardPresentPaymentStore.
//
public enum CardPresentPaymentAction: Action {
    /// Start the Card Reader discovery process.
    ///
    case startCardReaderDiscovery(siteID: Int64, onCompletion: ([CardReader]) -> Void)

    /// Cancels the Card Reader discovery process.
    ///
    case cancelCardReaderDiscovery(onCompletion: (CardReaderServiceDiscoveryStatus) -> Void)

    /// Connect to a specific CardReader.
    /// Stops Card Reader discovery
    ///
    case connect(reader: CardReader, onCompletion: (Result<[CardReader], Error>) -> Void)

    /// Collected payment for an order.
    ///
    case collectPayment(siteID: Int64, orderID: Int64, parameters: PaymentParameters, onCompletion: (Result<Bool, Error>) -> Void )
}
