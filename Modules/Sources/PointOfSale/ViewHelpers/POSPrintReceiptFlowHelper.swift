import Foundation

/// The effect the payment success screen should perform for a Print-receipt interaction.
enum POSPrintReceiptEffect: Equatable {
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
/// The view owns the `pendingPrintAfterSetup` state and performs the effects (printing, presenting
/// the setup modal); this only computes what should happen, so the flow can be unit-tested without
/// a view.
enum POSPrintReceiptFlowHelper {
    /// Merchant tapped Print. Print immediately when a printer is connected, otherwise present the
    /// inline setup flow (the caller then marks a print as pending).
    static func printButtonTapped(isPrinterConnected: Bool) -> POSPrintReceiptEffect {
        isPrinterConnected ? .print : .presentSetup
    }

    /// Printer connection state changed. Print once when a print was pending and a printer is now
    /// connected — i.e. the merchant connected through the setup flow they opened by tapping Print.
    static func printerConnectionChanged(isConnected: Bool, pendingPrintAfterSetup: Bool) -> POSPrintReceiptEffect {
        isConnected && pendingPrintAfterSetup ? .print : .none
    }

    /// Setup modal visibility changed. A pending print should be dropped when the modal closes
    /// without a printer connected — the merchant backed out — so a later unrelated connection
    /// can't trigger an unexpected print.
    static func shouldClearPendingPrint(isSetupPresented: Bool, isPrinterConnected: Bool) -> Bool {
        !isSetupPresented && !isPrinterConnected
    }
}
