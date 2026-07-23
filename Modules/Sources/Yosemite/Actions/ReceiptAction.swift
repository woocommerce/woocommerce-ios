/// ReceiptAction: Defines all of the Actions supported by the ReceiptStore.
///
public enum ReceiptAction: Action {
    /// Retrieves a receipt from the backend for a given `Order`
    case retrieveReceipt(order: Order, onCompletion: (Result<Receipt, Error>) -> Void)

    /// Sends a receipt to a customer email for a given `Order`.
    case sendReceipt(order: Order, email: String, onCompletion: (Result<Order, Error>) -> Void)
}
