import StripeTerminal

extension ReceiptDetails {

    /// Convenience initializer
    /// - Parameter reader: An instance of a StripeTerminal.ReceiptDetails
    init?(receiptDetails: StripeReceiptDetails?) {
        guard let details = receiptDetails else {
            return nil
        }
    }
}

protocol StripeReceiptDetails {
}


extension StripeTerminal.ReceiptDetails: StripeReceiptDetails { }
