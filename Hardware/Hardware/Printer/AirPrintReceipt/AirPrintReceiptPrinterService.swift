import UIKit

/// Barebones Implementation of the ReceiptPrinterService that integrates with AirPrint
/// Will be iterated in https://github.com/woocommerce/woocommerce-ios/issues/3982
public final class AirPrintReceiptPrinterService: PrinterService {
    public init() { }

    public func printReceipt(content: ReceiptContent, completion: @escaping (PrintingResult) -> Void) {
        let info = UIPrintInfo(dictionary: nil)
        // Will be localized in #3982
        info.jobName = "Order Receipt"
        info.orientation = .portrait
        info.duplex = .longEdge

        let renderer = ReceiptRenderer(content: content)

        let printController = UIPrintInteractionController.shared
        printController.printInfo = info
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
