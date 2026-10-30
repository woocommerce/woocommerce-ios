import Foundation
import CocoaLumberjackSwift

/// What the merchant chose in the print failure modal.
enum POSPrintReceiptFailureAction {
    case retry
    case emailReceipt
}

/// Orchestrates the Print-receipt flow on the payment success screen: decides between printing and
/// presenting printer setup (via `POSPrintReceiptFlowHelper`), performs the print, and tracks the
/// `receipt_print_*` analytics around it.
///
/// Stores only injected dependencies, never state — the effects (printing, presenting the setup
/// modal, showing progress and failures) are injected as closures, so the flow stays unit-testable
/// with a mock analytics provider and spy closures.
@MainActor
struct POSPrintReceiptCoordinator {
    private let analytics: POSAnalyticsProviding
    private let printReceipt: () async throws -> Void
    private let presentPrinterSetup: @MainActor () -> Void
    private let presentEmailReceipt: @MainActor () -> Void
    private let isOnSuccessScreen: @MainActor () -> Bool
    private let presentFailure: @MainActor (POSPrintReceiptFailure) -> Void
    private let updateButtonState: @MainActor (POSButtonState) -> Void

    init(analytics: POSAnalyticsProviding,
         printReceipt: @escaping () async throws -> Void,
         presentPrinterSetup: @escaping @MainActor () -> Void,
         presentEmailReceipt: @escaping @MainActor () -> Void,
         isOnSuccessScreen: @escaping @MainActor () -> Bool,
         presentFailure: @escaping @MainActor (POSPrintReceiptFailure) -> Void,
         updateButtonState: @escaping @MainActor (POSButtonState) -> Void) {
        self.analytics = analytics
        self.printReceipt = printReceipt
        self.presentPrinterSetup = presentPrinterSetup
        self.presentEmailReceipt = presentEmailReceipt
        self.isOnSuccessScreen = isOnSuccessScreen
        self.presentFailure = presentFailure
        self.updateButtonState = updateButtonState
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

    /// Merchant chose how to continue after a failed print. Retry follows the Print button path, so a
    /// printer that dropped its connection goes through setup instead of failing again.
    func failureActionSelected(_ action: POSPrintReceiptFailureAction, isPrinterConnected: Bool) async {
        switch action {
        case .retry:
            await printButtonTapped(isPrinterConnected: isPrinterConnected)
        case .emailReceipt:
            analytics.track(.receiptEmailTapped)
            presentEmailReceipt()
        }
    }

    private func performPrint() async {
        updateButtonState(.loading)
        do {
            try await printReceipt()
            analytics.track(.receiptPrintSuccess)
            updateButtonState(.success)
        } catch {
            DDLogError("⛔️ POS receipt print failed: \(error)")
            analytics.track(.receiptPrintFailed, parameters: [:], error: error)
            updateButtonState(.idle)
            // A print can fail after the merchant moved on to emailing the receipt, which must not be interrupted.
            if isOnSuccessScreen() {
                presentFailure(POSPrintReceiptFailure(error: error))
            }
        }
    }
}
