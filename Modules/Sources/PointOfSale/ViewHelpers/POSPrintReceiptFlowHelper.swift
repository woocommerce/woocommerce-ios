import Foundation

/// The action the payment success screen should perform for a Print-receipt interaction.
enum POSPrintReceiptFlowAction: Equatable {
    /// Print the current order's receipt now.
    case print
    /// Present the inline printer setup flow.
    case presentSetup
    /// Do nothing.
    case none
}

/// Stateless decision logic for the Print-receipt button and its connect-then-auto-print flow on
/// the payment success screen.
///
/// The view performs the actions (printing, presenting the setup modal); this only computes what
/// should happen, so the flow can be unit-tested without a view.
enum POSPrintReceiptFlowHelper {
    /// Merchant tapped Print. Print immediately when a printer is connected, otherwise present the
    /// inline setup flow.
    static func actionAfterPrintButtonTapped(isPrinterConnected: Bool) -> POSPrintReceiptFlowAction {
        isPrinterConnected ? .print : .presentSetup
    }

    /// Setup modal visibility changed. The modal auto-dismisses on connection, so it closing with a
    /// printer connected means the merchant completed the setup they opened by tapping Print — print
    /// then. Closing without a printer means they backed out, so do nothing.
    static func actionAfterSetupModalVisibilityChanged(isPresented: Bool, isPrinterConnected: Bool) -> POSPrintReceiptFlowAction {
        !isPresented && isPrinterConnected ? .print : .none
    }
}
