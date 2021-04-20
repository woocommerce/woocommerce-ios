public protocol ReceiptPrinterService {
    var isPrintingAvilable: Bool { get }

    func printReceipt(_ paymentIntent: PaymentIntent, from: PrintingSource?)
}
