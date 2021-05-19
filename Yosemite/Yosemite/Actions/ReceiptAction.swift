/// RefundAction: Defines all of the Actions supported by the ReceiptStore.
///
public enum ReceiptAction: Action {
    /// Prints a receipt for a given `Order` with the given `CardPresentReceiptParameters`
    case print(order: Order, parameters: CardPresentReceiptParameters, completion: (PrintingResult) -> Void)

    /// Generates content for a receipt for a given `Order` with the given `CardPresentReceiptParameters`
    /// The content is a String containing HTML
    case generateContent(order: Order, parameters: CardPresentReceiptParameters, onContent: (String) -> Void)

    /// Saves the metadata necessary to render a receipt
    case saveReceipt(order: Order, parameters: CardPresentReceiptParameters)

    /// Loads the metadata necessary to render a receipt
    case loadReceipt(order: Order, onCompletion: (Result<CardPresentReceiptParameters, Error>) -> Void)
}
