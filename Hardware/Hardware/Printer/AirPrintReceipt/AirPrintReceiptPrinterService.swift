import UIKit

/// Barebones Implementation of the ReceiptPrinterService that integrates with AirPrint
/// Will be iterated in https://github.com/woocommerce/woocommerce-ios/issues/3982
public final class AirPrintReceiptPrinterService: PrinterService {
    private let printInfo: UIPrintInfo = {
        let info = UIPrintInfo(dictionary: nil)
        // Will be localized in #3982
        info.jobName = "Order Receipt"
        info.orientation = .portrait
        info.duplex = .longEdge

        return info
    }()

    public init() { }

    public func printReceipt(content: ReceiptContent) {
        let printController = UIPrintInteractionController.shared

        printController.printInfo = printInfo

        let renderer = ReceiptRenderer(content: content)
        printController.printPageRenderer = renderer

        printController.present(animated: true, completionHandler: nil)
    }
}
