import Hardware

extension PaymentIntent {
    func regulatoryInfo() -> ReceiptRegulatoryInfo? {
        guard let paymentMethod = self.charges.first?.paymentMethod,
              case .presentCard(details: let cardDetails) = paymentMethod else {
            return nil
        }

        return ReceiptRegulatoryInfo(amount: amount,
                                     currency: currency,
                                     cardDetails: cardDetails)
    }
}
