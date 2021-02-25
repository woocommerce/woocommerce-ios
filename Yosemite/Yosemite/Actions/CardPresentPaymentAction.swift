// MARK: - CardPresentPaymentAction: Defines all of the Actions supported by the CardPresentPaymentStore.
//
public enum CardPresentPaymentAction: Action {
    /// Start the Card Reader discovery process.
    ///
    case startCardReaderDiscovery(onCompletion: ([CardReader]) -> Void)

    /// Connect to a specific CardReader.
    ///
    case connect(reader: CardReader, onCompletion: (Result<CardReader, Error>) -> Void)
}
