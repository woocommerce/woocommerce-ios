import Hardware

extension PaymentIntent {
    func regulatoryInfo() -> ReceiptRegulatoryInfo {
        return ReceiptRegulatoryInfo(amount: amount,
                                     currency: currency)
    }
}
