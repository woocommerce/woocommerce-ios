import Hardware

extension PaymentIntent {
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
