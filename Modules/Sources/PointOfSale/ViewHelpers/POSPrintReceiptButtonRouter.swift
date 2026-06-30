/// What a Print-receipt tap on the payment success screen should do, based on printer connection.
enum POSPrintReceiptTapAction: Equatable {
    /// No printer is connected — present the inline setup flow.
    case presentSetup
    /// A printer is already connected, so no setup is needed.
    case none
}

/// Stateless routing for the payment success Print-receipt tap.
struct POSPrintReceiptButtonRouter {
    func action(isPrinterConnected: Bool) -> POSPrintReceiptTapAction {
        isPrinterConnected ? .none : .presentSetup
    }
}
