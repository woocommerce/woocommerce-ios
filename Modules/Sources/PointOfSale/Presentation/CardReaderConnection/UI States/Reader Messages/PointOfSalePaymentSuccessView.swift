import SwiftUI

struct PointOfSalePaymentSuccessView: View {
    let viewModel: PointOfSalePaymentSuccessViewModel
    let customerEmail: String?
    let successAction: PaymentFlowAction
    let onSuccessScreenBarcodeScanned: ((Result<String, HIDBarcodeParserError>) -> Void)?
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var isViewLoaded: Bool = false
    @State private var showPrinterSetupModal: Bool = false
    @State private var printButtonState: POSButtonState = .idle
    @State private var printFailure: POSPrintReceiptFailure?
    @State private var selectedFailureAction: POSPrintReceiptFailureAction?
    @AccessibilityFocusState private var isTitleFocused: Bool
    @Environment(\.posNavigationRouter) private var router
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.posAnalytics) private var analytics

    private var isBarcodeScanningEnabled: Bool {
        onSuccessScreenBarcodeScanned != nil && !router.isNavigated
    }

    var body: some View {
        HStack(alignment: .center) {
            Spacer()
            successView
            Spacer()
        }
        .padding([.leading, .trailing], dynamicTypeSize.isAccessibilitySize ? nil : POSPadding.small)
        .background(Color.posSurfaceBright)
        .barcodeScanning(enabled: .constant(isBarcodeScanningEnabled)) { barcode in
            onSuccessScreenBarcodeScanned?(barcode)
        }
        .onAppear {
            Task { @MainActor in
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    isViewLoaded = true
                }
                isTitleFocused = true
            }
        }
        .posModal(isPresented: $showPrinterSetupModal) {
            if let controller = posModel.settingsController.printerConnectionController {
                POSPrinterSetupModal(isPresented: $showPrinterSetupModal, controller: controller)
            }
        }
        .onChange(of: showPrinterSetupModal) { _, isShowing in
            // The setup modal auto-dismisses when a printer connects, so the modal closing with a
            // printer connected means setup succeeded — print the receipt the merchant asked for.
            Task {
                await printCoordinator.setupModalVisibilityChanged(
                    isPresented: isShowing,
                    isPrinterConnected: posModel.isReceiptPrinterConnected)
            }
        }
        .posModal(item: $printFailure, onDismiss: handlePrintFailureDismissed) { failure in
            POSPrintReceiptFailureModal(failure: failure,
                                        selectAction: { action in
                                            selectedFailureAction = action
                                            printFailure = nil
                                        },
                                        close: { printFailure = nil })
        }
        .task(id: printButtonState) {
            guard printButtonState == .success else { return }
            try? await Task.sleep(for: Constants.printConfirmationDuration)
            guard !Task.isCancelled else { return }
            printButtonState = .idle
        }
    }

    private var printCoordinator: POSPrintReceiptCoordinator {
        POSPrintReceiptCoordinator(analytics: analytics,
                                   printReceipt: { try await posModel.printReceipt() },
                                   presentPrinterSetup: { showPrinterSetupModal = true },
                                   presentEmailReceipt: { router.pushEmailReceipt() },
                                   isOnSuccessScreen: { !router.isNavigated },
                                   presentFailure: { printFailure = $0 },
                                   updateButtonState: { printButtonState = $0 })
    }

    private func handlePrintReceiptTap() {
        guard printButtonState == .idle else { return }
        Task {
            await printCoordinator.printButtonTapped(isPrinterConnected: posModel.isReceiptPrinterConnected)
        }
    }

    /// Acts on the merchant's choice only once the failure modal has closed: `POSModalManager` holds one
    /// modal, so presenting printer setup alongside this dismissal could lose the new modal.
    private func handlePrintFailureDismissed() {
        guard let action = selectedFailureAction else { return }
        selectedFailureAction = nil
        Task {
            await printCoordinator.failureActionSelected(action, isPrinterConnected: posModel.isReceiptPrinterConnected)
        }
    }

    private var successView: some View {
        ZStack {
            VStack(alignment: .center, spacing: POSSpacing.none) {
                Spacer()

                POSSuccessIcon()
                    .renderedIf(!dynamicTypeSize.isAccessibilitySize)
                    .scaleEffect(isViewLoaded ? 1 : 0)
                    .opacity(isViewLoaded ? 1 : 0)

                Spacer().frame(height: POSSpacing.xLarge)

                VStack(alignment: .center, spacing: Constants.textSpacing) {
                    Text(viewModel.title)
                        .font(.posHeadingBold)
                        .foregroundStyle(Color.posOnSurface)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($isTitleFocused)
                        .accessibilityIdentifier("pos-payment-success-view")
                        .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                        .opacity(isViewLoaded ? 1 : 0)

                    if let message = viewModel.message {
                        Text(message)
                            .font(.posBodyLargeRegular())
                            .foregroundStyle(Color.posOnSurface)
                            .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                            .opacity(isViewLoaded ? 1 : 0)
                    }
                }

                if let customerEmail, customerEmail.isNotEmpty {
                    Spacer().frame(height: Constants.textSpacing)

                    Text(String(format: Localization.receiptSentFormat, customerEmail))
                        .font(.posBodyLargeRegular())
                        .foregroundStyle(Color.posOnSurface)
                        .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                        .opacity(isViewLoaded ? 1 : 0)
                }

                Spacer().frame(height: POSSpacing.xxLarge)

                // iPad: buttons take half the screen width (count:2 span:1).
                // Phone: half the screen width is ~190pt, too narrow for "New order" /
                // "Email receipt" — let them span the container minus standard insets instead.
                PaymentsActionButtons(successAction: successAction,
                                      showsPrintReceipt: posModel.receiptPrinter != nil,
                                      printButtonState: printButtonState,
                                      printReceiptAction: handlePrintReceiptTap)
                    .if(horizontalSizeClass != .compact) { view in
                        view.containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: POSSpacing.none)
                    }
                    .if(horizontalSizeClass == .compact) { view in
                        view.padding(.horizontal, POSPadding.large)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .offset(y: isViewLoaded ? 0 : -Constants.animationOffset)
                    .opacity(isViewLoaded ? 1 : 0)

                Spacer()
            }
            .multilineTextAlignment(.center)
        }
    }
}

private extension PointOfSalePaymentSuccessView {
    enum Constants {
        static let textSpacing: CGFloat = POSSpacing.small
        static let animationOffset: CGFloat = 100
        static let printConfirmationDuration: Duration = .seconds(2)
    }

    enum Localization {
        static let receiptSentFormat = NSLocalizedString(
            "pointOfSale.paymentSuccessful.receiptSent",
            value: "A receipt has been sent to %1$@.",
            comment: "Informational message shown on payment success screen when an email receipt is automatically sent. " +
            "%1$@ is a placeholder for the customer's email address."
        )
    }
}

#if DEBUG
#Preview {
    let model = POSPreviewHelpers.makePreviewAggregateModel(
        receiptPrinter: POSReceiptPrinterPreviewService()
    )
    PointOfSalePaymentSuccessView(
        viewModel: PointOfSalePaymentSuccessViewModel(formattedOrderTotal: "$3.00",
                                                      paymentMethod: .card),
        customerEmail: "test@example.com",
        successAction: PaymentFlowAction(title: "New order", action: {}, analyticsEvent: nil),
        onSuccessScreenBarcodeScanned: nil
    )
    .environment(model)
}
#endif
