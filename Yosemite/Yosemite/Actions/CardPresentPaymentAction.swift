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

    /// Calls the completion block everytime the list of known readers changes
    /// with an array of readers known to us.
    ///
    /// What does "known" mean?
    /// If the user connects to a reader, we declare it known. If the user explicitly disconnects from a reader,
    /// we treat that as a "forget" request and un-declare known-ness. During discovery, if a known reader is
    /// detected, it should be connected to automatically. The list of known readers (most merchants will only
    /// have 1 or 2) will be persisted across application sessions.
    case observeKnownReaders(onCompletion: ([CardReader]) -> Void)

    /// Calls the completion block everytime the list of connected readers changes
    /// with an array of connected readers.
    ///
    case observeConnectedReaders(onCompletion: ([CardReader]) -> Void)

    /// Collected payment for an order.
    ///
    case collectPayment(siteID: Int64,
                        orderID: Int64,
                        parameters: PaymentParameters,
                        onCardReaderMessage: (CardReaderEvent) -> Void,
                        onCompletion: (Result<CardPresentReceiptParameters, Error>) -> Void )

    case checkForCardReaderUpdate(onData: (Result<CardReaderSoftwareUpdate, Error>) -> Void,
                        onCompletion: () -> Void)

    case startCardReaderUpdate(onProgress: (Float) -> Void,
                        onCompletion: (Result<Void, Error>) -> Void)

}
