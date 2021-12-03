import UIKit

/// Barebones Implementation of the ReceiptPrinterService that integrates with AirPrint
/// Will be iterated in https://github.com/woocommerce/woocommerce-ios/issues/3982
public final class AirPrintReceiptPrinterService: NSObject, PrinterService {
    private var receiptContent: ReceiptContent?

    public func printReceipt(content: ReceiptContent, completion: @escaping (PrintingResult) -> Void) {
        self.receiptContent = content

        let info = UIPrintInfo(dictionary: nil)
        // Will be localized in #3982
        info.jobName = "Order Receipt"
        info.orientation = .portrait
        info.duplex = .longEdge

        let printController = UIPrintInteractionController.shared
        printController.printInfo = info
        printController.delegate = self

        let renderer = ReceiptRenderer(content: content)
        printController.printPageRenderer = renderer

        printController.present(animated: true) { (controller, completed, error) in
            switch (completed, error) {
            case (_, .some(let error)):
                // Printing failed
                completion(.failure(error))
            case (true, .none):
                // Successful print job
                completion(.success)
            case (false, .none):
                // User canceled the print job
                completion(.cancel)
            }
        }
    }
}

extension AirPrintReceiptPrinterService: UIPrintInteractionControllerDelegate {
    public func printInteractionController(_ printInteractionController: UIPrintInteractionController, choosePaper paperList: [UIPrintPaper]) -> UIPrintPaper {
        let pageSize = self.receiptContent?.preferredPageSizeForPrinting ?? AirPrintReceiptPrinterService.defaultReceiptPageSize
        return UIPrintPaper.bestPaper(forPageSize: pageSize, withPapersFrom: paperList)
    }

    public func printInteractionController(_ printInteractionController: UIPrintInteractionController, cutLengthFor paper: UIPrintPaper) -> CGFloat {
        let pageSize = self.receiptContent?.preferredPageSizeForPrinting ?? AirPrintReceiptPrinterService.defaultReceiptPageSize
        return pageSize.height + AirPrintReceiptPrinterService.defaultRollCutterMargin
    }
}

extension AirPrintReceiptPrinterService {
    static let pointsPerInch: Int = 72

    /// Default margin for roll cutter.
    ///
    static let defaultRollCutterMargin: CGFloat = CGFloat(1 * pointsPerInch)

    /// Default size of a page for a receipt in points.
    ///
    static let defaultReceiptPageSize: CGSize = CGSize(width: 4 * pointsPerInch, height: 11 * pointsPerInch)
}
