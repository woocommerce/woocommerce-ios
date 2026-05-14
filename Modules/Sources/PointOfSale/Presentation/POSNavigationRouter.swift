import SwiftUI

struct POSNavigationRouter {
    @Binding var navigationPath: [POSNavigationDestination]

    var isNavigated: Bool { !navigationPath.isEmpty }

    func pushCash(orderTotal: String) {
        guard navigationPath.isEmpty else { return }
        navigationPath.append(.cashPayment(orderTotal: orderTotal))
    }

    func pushScanToPay(orderTotal: String) {
        guard navigationPath.isEmpty else { return }
        navigationPath.append(.scanToPay(orderTotal: orderTotal))
    }

    func pushMarkAsPaid(orderTotal: String) {
        guard navigationPath.isEmpty else { return }
        navigationPath.append(.markAsPaid(orderTotal: orderTotal))
    }

    func pushEmailReceipt() {
        navigationPath.append(.emailReceipt)
    }

    func pop() {
        guard !navigationPath.isEmpty else { return }
        navigationPath.removeLast()
    }

    func popToRoot() {
        navigationPath.removeAll()
    }
}

// MARK: - Navigation Destination Wrappers

/// Thin wrapper that resolves environment dependencies for the cash payment NavigationStack destination.
struct POSNavigationDestinationCashPaymentView: View {
    let orderTotal: String
    @Environment(\.posCurrencyProvider) private var currencyProvider

    var body: some View {
        PointOfSaleCollectCashView(orderTotal: orderTotal,
                                   currencySettings: currencyProvider.currencySettings)
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Thin wrapper that resolves environment dependencies for the scan-to-pay NavigationStack destination.
struct POSNavigationDestinationScanToPayView: View {
    let orderTotal: String

    var body: some View {
        PointOfSaleScanToPayView(orderTotal: orderTotal)
            .navigationBarHidden(true)
            // Asks the dashboard to hide the floating control overlay (`…` menu, reader chip)
            // while the merchant is on the QR-based payment screen.
            .posHidesFloatingControl()
    }
}

/// Thin wrapper that hosts the Mark-as-paid confirmation as a NavigationStack push destination.
///
/// The confirmation lives in the right pane like cash and scan-to-pay rather than as an overlay
/// alert. Hosting it inside the `NavigationStack` gives us:
///
/// - the same in-pane navigation pattern as cash and scan-to-pay (no special-case modifier)
/// - "back" semantics for free (chevron-back, edge swipe)
/// - the same `navigationPath`-based check used to hide floating dashboard controls
/// - no modal-stack optics (no "sheet → alert" chain, no auto-dismiss binding hack)
///
/// Submission errors render inline inside the view (existing `errorMessage` parameter), so the
/// merchant never has to re-navigate to retry.
struct POSNavigationDestinationMarkAsPaidView: View {
    let orderTotal: String
    @Environment(POSPaymentModel.self) private var paymentModel
    @Environment(\.posNavigationRouter) private var router
    @State private var errorMessage: String?

    var body: some View {
        PointOfSaleMarkAsPaidConfirmationView(
            orderTotal: orderTotal,
            isProcessing: paymentModel.paymentState.markAsPaid == .processing,
            errorMessage: errorMessage,
            onConfirm: { note in
                Task { @MainActor in
                    do {
                        try await paymentModel.confirmMarkAsPaidPayment(note: note)
                        errorMessage = nil
                    } catch {
                        errorMessage = Localization.failureMessage
                    }
                }
            },
            onCancel: {
                Task { @MainActor in
                    await paymentModel.cancelMarkAsPaidPayment()
                    router.pop()
                }
            }
        )
        .navigationBarHidden(true)
        // Fill the right pane so the visual transition reads as "totals → confirmation → totals"
        // rather than a card landing on top.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurface)
        // Asks the dashboard to hide the floating control overlay (`…` menu, reader chip)
        // so the merchant can focus on the confirmation step without distractions.
        .posHidesFloatingControl()
    }

    private enum Localization {
        static let failureMessage = NSLocalizedString(
            "pointOfSale.markAsPaid.failureMessage",
            value: "Couldn't mark this order as paid. Try again.",
            comment: "Error shown on the Point of Sale Mark as paid confirmation when the network call fails."
        )
    }
}

/// Thin wrapper that resolves environment dependencies for the email receipt NavigationStack destination.
struct POSNavigationDestinationEmailReceiptView: View {
    @Environment(POSPaymentModel.self) private var paymentModel
    @Environment(\.posNavigationRouter) private var router

    var body: some View {
        POSSendReceiptView(onDismiss: {
            router.pop()
        }) { email in
            try await paymentModel.sendReceipt(to: email)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

extension View {
    /// Routes every `POSNavigationDestination` case to its wrapper view.
    /// Kept in one place so the phone and iPad `NavigationStack`s can't drift
    /// out of sync when a new destination is added.
    func posNavigationDestinations() -> some View {
        navigationDestination(for: POSNavigationDestination.self) { destination in
            switch destination {
            case .cashPayment(let orderTotal):
                POSNavigationDestinationCashPaymentView(orderTotal: orderTotal)
            case .scanToPay(let orderTotal):
                POSNavigationDestinationScanToPayView(orderTotal: orderTotal)
            case .markAsPaid(let orderTotal):
                POSNavigationDestinationMarkAsPaidView(orderTotal: orderTotal)
            case .emailReceipt:
                POSNavigationDestinationEmailReceiptView()
            }
        }
    }
}
