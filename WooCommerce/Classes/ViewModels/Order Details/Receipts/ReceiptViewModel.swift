import Yosemite

/// ViewModel supporting the backed-generated receipt preview.
final class ReceiptViewModel {
    private let receipt: Receipt
    private let orderID: Int64

    init(receipt: Receipt, orderID: Int64) {
        self.receipt = receipt
        self.orderID = orderID
    }

    var receiptURLString: String {
        receipt.receiptURL
    }

    var receiptRequest: URLRequest? {
        guard let url = URL(string: receipt.receiptURL) else {
            return nil
        }
        return URLRequest(url: url)
    }

    func formattedReceiptJobName(_ jobName: String) -> String {
        String.localizedStringWithFormat(Localization.receiptJobName, jobName, String(orderID))
    }
}

private extension ReceiptViewModel {
    enum Localization {
        static let receiptJobName = NSLocalizedString(
            "receiptViewModel.formattedReceiptJobName",
            value: "%1$@: receipt for order #%2$@",
            comment: "The name of the job that appears in the 'Print Center' when printing a receipt" +
            "Reads as 'Woo: receipt for order #123'")
    }
}
