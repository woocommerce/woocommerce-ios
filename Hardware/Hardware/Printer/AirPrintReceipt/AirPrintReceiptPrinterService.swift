import UIKit

/// Implementation of the ReceiptPrinterService that integrates with AirPrint
public final class AirPrintReceiptPrinterService: ReceiptPrinterService {
    public init() { }

    public var isPrintingAvilable: Bool {
        UIPrintInteractionController.isPrintingAvailable
    }

    public func printReceipt(content: ReceiptContent) {
        let printController = UIPrintInteractionController.shared

        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = "Order Receipt"
        printInfo.orientation = .portrait
        printInfo.duplex = .longEdge

        printController.printInfo = printInfo

        let renderer = ReceiptRenderer(content: content)
        printController.printPageRenderer = renderer

        printController.present(animated: true, completionHandler: nil)
    }
}
