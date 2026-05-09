import SwiftUI
import UIKit
import WooFoundation

/// Full-screen scan-to-pay view: shows a QR code encoding the order's gateway-hosted payment
/// URL, polls the backend for payment status, and gives the merchant a manual "Mark payment as
/// complete" fallback in case the gateway webhook is slow.
///
/// Lifecycle:
/// 1. Loading — `paymentModel.isPreparingScanToPay` is true while the autoDraft → pending
///    promotion is in flight. Renders a placeholder spinner the same size as the QR.
/// 2. QR shown — `scanToPayURL` is populated. Verification status under the QR shows the polling
///    state (waiting / error / confirming).
/// 3. Success — `paymentModel.paymentState.scanToPay == .paymentSuccess` triggers `popToRoot`;
///    the totals view takes over with the standard payment-success UI.
struct PointOfSaleScanToPayView: View {
    @Environment(\.posNavigationRouter) private var router
    @Environment(POSPaymentModel.self) private var paymentModel

    private let orderTotal: String

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    /// Brightness captured the first time the view appears so we can restore it on disappear.
    /// Stored in `@State` rather than a `let` because SwiftUI re-creates view structs on parent
    /// re-renders; a stored property would be reinitialized to the current (already-bumped)
    /// brightness, leaving the device stuck at max brightness after the merchant leaves the screen.
    @State private var savedScreenBrightness: CGFloat?

    init(orderTotal: String) {
        self.orderTotal = orderTotal
    }

    var body: some View {
        content
            .onAppear {
                if savedScreenBrightness == nil {
                    savedScreenBrightness = UIScreen.main.brightness
                }
                UIScreen.main.brightness = 1.0
            }
            .onDisappear {
                if let savedScreenBrightness {
                    UIScreen.main.brightness = savedScreenBrightness
                }
            }
            .onChange(of: paymentModel.paymentState.scanToPay) { _, newValue in
                switch newValue {
                case .paymentSuccess, .idle:
                    router.popToRoot()
                case .showingQRCode:
                    break
                }
            }
    }

    /// Pulls the verification status out of the underlying state so the view can render
    /// the right indicator without leaking the enum shape into multiple places.
    private var verificationStatus: ScanToPayVerificationStatus {
        if case let .showingQRCode(verification) = paymentModel.paymentState.scanToPay {
            return verification
        }
        return .waiting
    }

    private var content: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center, spacing: POSSpacing.medium) {
                    POSPageHeaderView(
                        title: Localization.title,
                        subtitle: String.localizedStringWithFormat(Localization.subtitle, orderTotal),
                        backButtonConfiguration: .init(state: isLoading ? .disabled : .enabled,
                                                       action: {
                                                           Task { @MainActor in
                                                               await paymentModel.cancelScanToPayPayment()
                                                               router.popToRoot()
                                                           }
                                                       }))

                    Spacer()

                    qrCodeContent

                    verificationStatusView

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.posBodySmallRegular())
                            .foregroundColor(.posError)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, POSPadding.medium)
                    }

                    Spacer()

                    Button(action: {
                        Task { @MainActor in
                            await markPaymentReceived()
                        }
                    }, label: {
                        Text(Localization.markPaymentCompletedButtonTitle)
                    })
                    .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: isLoading))
                    .disabled(isLoading || paymentModel.isPreparingScanToPay)
                    .padding([.horizontal, .bottom], POSPadding.medium)
                    .frame(maxWidth: .infinity)
                    .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                }
                .frame(minHeight: geometry.size.height)
                .animation(.easeInOut, value: errorMessage)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.posSurface)
    }

    @ViewBuilder
    private var qrCodeContent: some View {
        if let qrImage = generatedQRCodeImage() {
            VStack(spacing: POSSpacing.small) {
                Text(Localization.scanInstruction)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurface)
                    .multilineTextAlignment(.center)

                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: Layout.qrCodeSize, height: Layout.qrCodeSize)
                    .padding(POSPadding.medium)
                    .background(Color.white)
                    .cornerRadius(Layout.cornerRadius)
            }
            .padding(.horizontal, POSPadding.medium)
        } else if paymentModel.isPreparingScanToPay {
            // The QR is being generated server-side: still waiting on the autoDraft → pending
            // promotion to populate `paymentURL`. Show a placeholder of the same size so the
            // layout doesn't shift when the QR appears.
            VStack(spacing: POSSpacing.medium) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
                    .frame(width: Layout.qrCodeSize, height: Layout.qrCodeSize)

                Text(Localization.preparing)
                    .font(.posBodyLargeRegular())
                    .foregroundColor(.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, POSPadding.medium)
        } else {
            Text(Localization.qrUnavailable)
                .font(.posBodyLargeRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)
                .padding(.horizontal, POSPadding.medium)
        }
    }

    private func generatedQRCodeImage() -> UIImage? {
        guard let url = paymentModel.scanToPayURL else { return nil }
        return url.generateQRCode()
    }

    /// Live status indicator showing whether the backend has detected payment.
    /// Hidden while preparing (the spinner inside the QR area covers that case) or
    /// when the URL never came back (the unavailable message takes its place).
    @ViewBuilder
    private var verificationStatusView: some View {
        if paymentModel.scanToPayURL != nil {
            HStack(spacing: POSSpacing.small) {
                statusIcon
                Text(verificationStatusMessage)
                    .font(.posBodyMediumRegular())
                    .foregroundColor(verificationStatusColor)
            }
            .padding(.horizontal, POSPadding.medium)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(verificationStatusMessage)
            .animation(.easeInOut, value: verificationStatus)
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch verificationStatus {
        case .waiting:
            ProgressView()
                .progressViewStyle(.circular)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.posError)
        case .confirming:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.posPrimary)
        }
    }

    private var verificationStatusMessage: String {
        switch verificationStatus {
        case .waiting:
            return Localization.statusWaiting
        case .error:
            return Localization.statusError
        case .confirming:
            return Localization.statusConfirming
        }
    }

    private var verificationStatusColor: Color {
        switch verificationStatus {
        case .waiting:
            return .posOnSurfaceVariantHighest
        case .error:
            return .posError
        case .confirming:
            return .posOnSurface
        }
    }
}

private extension PointOfSaleScanToPayView {
    @MainActor
    func markPaymentReceived() async {
        errorMessage = nil
        isLoading = true
        do {
            try await paymentModel.completeScanToPayPayment()
        } catch {
            errorMessage = Localization.failedToConfirmPayment
        }
        isLoading = false
    }
}

private extension PointOfSaleScanToPayView {
    enum Layout {
        static let qrCodeSize: CGFloat = 280
        static let cornerRadius: CGFloat = 8
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.scanToPay.navigation.title",
            value: "Scan to Pay",
            comment: "Title for the Point of Sale scan-to-pay screen"
        )
        static let subtitle = NSLocalizedString(
            "pointOfSale.scanToPay.navigation.subtitle",
            value: "Total: %1$@",
            comment: "Subtitle showing the order total on the Point of Sale scan-to-pay screen. " +
            "Reads as 'Total: $1.23'"
        )
        static let scanInstruction = NSLocalizedString(
            "pointOfSale.scanToPay.scan.instruction",
            value: "Ask the customer to scan the QR code with their phone to complete the payment.",
            comment: "Instruction text shown above the QR code in the Point of Sale scan-to-pay screen."
        )
        static let qrUnavailable = NSLocalizedString(
            "pointOfSale.scanToPay.qrUnavailable.message",
            value: "We couldn't generate a QR code for this order. Please try a different payment method.",
            comment: "Message shown when no payment URL is available to render a QR code in Point of Sale scan-to-pay."
        )
        static let preparing = NSLocalizedString(
            "pointOfSale.scanToPay.preparing.message",
            value: "Generating QR code…",
            comment: "Loading message shown while preparing the order for scan-to-pay (promoting it to pending)."
        )
        static let markPaymentCompletedButtonTitle = NSLocalizedString(
            "pointOfSale.scanToPay.markpaymentcompleted.button.title",
            value: "Mark payment as complete",
            comment: "Button to confirm a scan-to-pay payment was received in Point of Sale."
        )
        static let failedToConfirmPayment = NSLocalizedString(
            "pointOfSale.scanToPay.failedToConfirmPayment.errorMessage",
            value: "Error confirming payment. Try again.",
            comment: "Error message shown when confirming a scan-to-pay payment fails in Point of Sale."
        )
        static let statusWaiting = NSLocalizedString(
            "pointOfSale.scanToPay.status.waiting",
            value: "Waiting for payment…",
            comment: "Status text shown under the scan-to-pay QR code while polling for payment."
        )
        static let statusError = NSLocalizedString(
            "pointOfSale.scanToPay.status.error",
            value: "Couldn't check payment status. Retrying…",
            comment: "Status text shown when polling for scan-to-pay payment fails (network etc.). Polling will retry."
        )
        static let statusConfirming = NSLocalizedString(
            "pointOfSale.scanToPay.status.confirming",
            value: "Payment received. Confirming…",
            comment: "Status text shown after the backend confirms a scan-to-pay payment, " +
            "while the app finalizes success."
        )
    }
}

#if DEBUG
#Preview {
    let model = POSPreviewHelpers.makePreviewAggregateModel()
    PointOfSaleScanToPayView(orderTotal: "$24.99")
        .environment(model.paymentModel)
}
#endif
