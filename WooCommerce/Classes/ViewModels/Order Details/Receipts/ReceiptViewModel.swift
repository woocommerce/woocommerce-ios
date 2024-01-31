import Yosemite

/// ViewModel supporting the backed-generated receipt preview.
struct ReceiptViewModel {
    private let receipt: Receipt

    init(receipt: Receipt) {
        self.receipt = receipt
    }

    var receiptURLString: String {
        receipt.receiptURL
    }
}
