import Yosemite

/// ViewModel supporting the backed-generated receipt preview.
final class ReceiptViewModel {
    private let receipt: Receipt
    private(set) var orderID: Int64
    private let siteName: String?

    init(receipt: Receipt, orderID: Int64, siteName: String?) {
        self.receipt = receipt
        self.orderID = orderID
        self.siteName = siteName
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
        if let siteName = siteName, !siteName.isEmpty {
            return String.localizedStringWithFormat(Localization.receiptJobNameWithStoreName,
                                                    jobName,
                                                    String(orderID),
                                                    siteName)
        } else {
            return String.localizedStringWithFormat(Localization.receiptJobName,
                                                    jobName,
                                                    String(orderID))
        }
    }
}

private extension ReceiptViewModel {
    enum Localization {
        static let receiptJobNameWithStoreName = NSLocalizedString(
            "receiptViewModel.formattedReceiptJobName.receiptJobNameWithStoreName",
            value: "%1$@: receipt for order #%2$@ on %3$@",
            comment: "The name of the job that appears in the 'Print Center' when printing a receipt" +
            "Reads as 'Woo: receipt for order #123 on MyStoreName'")

        static let receiptJobName = NSLocalizedString(
            "receiptViewModel.formattedReceiptJobName.receiptJobName",
            value: "%1$@: receipt for order #%2$@",
            comment: "The name of the job that appears in the 'Print Center' when printing a receipt" +
            "Reads as 'Woo: receipt for order #123'")
    }
}
