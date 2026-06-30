import Foundation

/// Stateless routing for the payment success Print-receipt tap.
struct POSPrintReceiptButtonRouter {
    /// Whether tapping Print should present the inline printer setup flow.
    func shouldPresentSetup(isPrinterConnected: Bool) -> Bool {
        !isPrinterConnected
    }
}
