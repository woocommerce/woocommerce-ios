import Foundation
import CocoaLumberjackSwift

/// Orchestrates the Print-receipt flow on the payment success screen: decides between printing and
/// presenting printer setup (via `POSPrintReceiptFlowHelper`), performs the print, and tracks the
/// `receipt_print_*` analytics around it.
///
/// Stores only injected dependencies, never state — the effects (printing, presenting the setup
/// modal) are injected as closures, so the flow stays unit-testable with a mock analytics provider
/// and spy closures.
@MainActor
struct POSPrintReceiptCoordinator {
    private let analytics: POSAnalyticsProviding
    private let printReceipt: () async throws -> Void
    private let presentPrinterSetup: @MainActor () -> Void

    init(analytics: POSAnalyticsProviding,
         printReceipt: @escaping () async throws -> Void,
         presentPrinterSetup: @escaping @MainActor () -> Void) {
        self.analytics = analytics
        self.printReceipt = printReceipt
        self.presentPrinterSetup = presentPrinterSetup
    }

    /// Merchant tapped Print. Prints immediately when a printer is connected, otherwise presents
    /// the printer setup flow via the injected closure.
    func printButtonTapped(isPrinterConnected: Bool) async {
        analytics.track(.receiptPrintTapped)
        switch POSPrintReceiptFlowHelper.actionAfterPrintButtonTapped(isPrinterConnected: isPrinterConnected) {
        case .presentSetup:
            presentPrinterSetup()
        case .print:
            await performPrint()
        case .none:
            break
        }
    }

    /// Setup modal visibility changed. Auto-prints when the modal closed because the merchant
    /// completed the setup they opened by tapping Print.
    func setupModalVisibilityChanged(isPresented: Bool, isPrinterConnected: Bool) async {
        if POSPrintReceiptFlowHelper.actionAfterSetupModalVisibilityChanged(
            isPresented: isPresented,
            isPrinterConnected: isPrinterConnected) == .print {
            await performPrint()
        }
    }

    private func performPrint() async {
        do {
            try await printReceipt()
            analytics.track(.receiptPrintSuccess)
        } catch {
            // Print-failure UX (retry + email fallback) is deferred to a follow-up; log for now.
            DDLogError("⛔️ POS receipt print failed: \(error)")
            analytics.track(.receiptPrintFailed, parameters: [:], error: error)
        }
    }
}
