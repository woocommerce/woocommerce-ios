/// ReceiptAction: Defines all of the Actions supported by the ReceiptStore.
///
public enum ReceiptAction: Action {
    /// Prints a locally-generated receipt for a given `Order` with the given `CardPresentReceiptParameters`
    case print(order: Order, parameters: CardPresentReceiptParameters, completion: (PrintingResult) -> Void)

    /// Generates content for a locally-generated receipt for a given `Order` with the given `CardPresentReceiptParameters`
    /// The content is a String containing HTML
    case generateContent(order: Order, parameters: CardPresentReceiptParameters, onContent: (String) -> Void)

    /// Saves the metadata necessary to render a locally-generated receipt
    case saveReceipt(order: Order, parameters: CardPresentReceiptParameters)

    /// Loads the metadata necessary to render a locally-generated receipt
    case loadReceipt(order: Order, onCompletion: (Result<CardPresentReceiptParameters, Error>) -> Void)

    /// Retrieves a receipt from the backend for a given `Order`
    case retrieveReceipt(order: Order, onCompletion: (Result<Receipt, Error>) -> Void)
}
