import Hardware

extension PaymentIntent {
    /// Maps a PaymentIntent into an struct that contains only the data we need to
    /// render a receips.
    /// - Returns: an optional struct containing all the data that needs to go into a receipt
    func receiptParameters() -> ReceiptParameters? {
        guard let paymentMethod = self.charges.first?.paymentMethod,
              case .presentCard(details: let cardDetails) = paymentMethod else {
            return nil
        }

        return ReceiptParameters(amount: amount,
                                     currency: currency,
                                     cardDetails: cardDetails)
    }
}
