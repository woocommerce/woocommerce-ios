import UIKit

public final class AirPrintReceiptPrinterService: ReceiptPrinterService {
    //private let printController = UIPrintInteractionController.shared
    public init() { }

    public var isPrintingAvilable: Bool {
        UIPrintInteractionController.isPrintingAvailable
    }

    public func printReceipt(_ paymentIntent: PaymentIntent, from: PrintingSource?) {
        let printController = UIPrintInteractionController.shared

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Order Receipt"
        printInfo.orientation = .portrait
        printInfo.duplex = .longEdge

        printController.printInfo = printInfo

        let renderer = ReceiptRenderer(intent: paymentIntent)
        printController.printPageRenderer = renderer

        printController.present(animated: true, completionHandler: nil)
    }
}
