import SwiftUI

struct POSCashSessionPrintButton: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel: PointOfSaleAggregateModel?

    let session: POSCashSession
    let money: POSCashSessionMoney

    @State private var isPrinting = false
    @State private var showsPrinterSetup = false
    @State private var showsPrintError = false

    var body: some View {
        Button {
            guard posModel?.receiptPrinter != nil else {
                showsPrintError = true
                return
            }
            if posModel?.isReceiptPrinterConnected == true {
                Task { await printSummary() }
            } else {
                showsPrinterSetup = true
            }
        } label: {
            Image(systemName: "printer")
                .frame(width: 20, height: 20)
        }
        .buttonStyle(POSInfoCardButtonStyle(size: .compact, variant: .default, isLoading: isPrinting))
        .disabled(session.closedAt == nil || isPrinting)
        .accessibilityLabel(Localization.printSession)
        .accessibilityIdentifier("pos-cash-session-print")
        .posModal(isPresented: $showsPrinterSetup) {
            if let controller = posModel?.settingsController.printerConnectionController {
                POSPrinterSetupModal(isPresented: $showsPrinterSetup, controller: controller)
            }
        }
        .onChange(of: showsPrinterSetup) { _, isShowing in
            if !isShowing && posModel?.isReceiptPrinterConnected == true {
                Task { await printSummary() }
            }
        }
        .alert(Localization.printFailed, isPresented: $showsPrintError) {
            Button(Localization.dismiss, role: .cancel) {}
        } message: {
            Text(Localization.printFailedMessage)
        }
    }

    @MainActor
    private func printSummary() async {
        guard !isPrinting, let printer = posModel?.receiptPrinter else { return }
        isPrinting = true
        defer { isPrinting = false }
        do {
            let text = POSCashSessionPrintFormatter.text(for: session, money: money)
            try await printer.printText(text)
        } catch {
            showsPrintError = true
        }
    }
}

private extension POSCashSessionPrintButton {
    enum Localization {
        static let printSession = NSLocalizedString("pos.cashSession.detail.print", value: "Print session", comment: "Print a closed cash session summary")
        static let printFailed = NSLocalizedString("pos.cashSession.detail.printFailed", value: "Could not print session",
                                                comment: "Cash session print error heading")
        static let printFailedMessage = NSLocalizedString("pos.cashSession.detail.printFailedMessage",
                                                       value: "Check the receipt printer and try again.", comment: "Cash session print error message")
        static let dismiss = NSLocalizedString("pos.cashSession.detail.printDismiss", value: "OK", comment: "Dismiss the cash session print error")
    }
}
