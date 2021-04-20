import UIKit

public final class AirPrintReceiptPrinterService: ReceiptPrinterService {
    public var isPrintingAvilable: Bool {
        UIPrintInteractionController.isPrintingAvailable
    }

    public func printReceipt(_ paymentIntent: PaymentIntent, from: PrintingSource) {
        print("==== printing receipt for ", paymentIntent)
        let printController = UIPrintInteractionController.shared

        let printInfo = UIPrintInfo()
        printInfo.jobName = "Order Receipt"
        // Set duplex so that it is available if the printer supports it. We are
        // performing portrait printing so we want to duplex along the long edge.
        printInfo.duplex = .longEdge

        printController.printInfo = printInfo
    }
}
