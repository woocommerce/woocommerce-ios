/// RefundAction: Defines all of the Actions supported by the ReceiptStore.
///  
public enum ReceiptAction: Action {
    /// Prints a receipt for a given `Order` with the given `CardPresentReceiptParameters`
    case print(order: Order, parameters: CardPresentReceiptParameters)

    /// Generates content for a receipt for a given `Order` with the given `CardPresentReceiptParameters`
    /// The content is a String containing HTML
    case generateContent(order: Order, parameters: CardPresentReceiptParameters, onContent: (String) -> Void)
}
