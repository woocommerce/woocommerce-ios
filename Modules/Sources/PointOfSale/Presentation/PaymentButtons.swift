import SwiftUI
import enum Hardware.DeviceStatus

struct PaymentsActionButtons: View {
    let successAction: PaymentFlowAction
    let printerConnectionState: DeviceStatus
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posFeatureFlags) private var featureFlags
    @Binding var isShowingReceiptModal: Bool
    @Binding var isShowingSendReceiptView: Bool

    private var isPrinterConnected: Bool {
        if case .connected = printerConnectionState { return true }
        return false
    }

    private var showPrinterFeature: Bool {
        featureFlags.isFeatureFlagEnabled(.starReceiptPrinterSupport)
    }

    var body: some View {
        VStack(spacing: POSSpacing.small) {
            successButton
            if showPrinterFeature && isPrinterConnected {
                receiptButton
            } else {
                emailReceiptButton
                if showPrinterFeature {
                    printerHint
                }
            }
        }
    }
}

private extension PaymentsActionButtons {
    var receiptButton: some View {
        Button(action: {
            isShowingReceiptModal = true
        }, label: {
            Text(Localization.receipt)
        })
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
    }

    var emailReceiptButton: some View {
        Button(action: {
            analytics.track(.receiptEmailTapped)
            isShowingSendReceiptView = true
        }, label: {
            Text(Localization.emailReceipt)
        })
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
    }

    var successButton: some View {
        Button(action: {
            if let event = successAction.analyticsEvent {
                analytics.track(event)
            }
            successAction.action()
        }, label: {
            Text(successAction.title)
        })
        .buttonStyle(POSFilledButtonStyle(size: .normal))
    }

    var printerHint: some View {
        Text(Localization.printerHint)
            .font(.posBodyMediumRegular())
            .foregroundStyle(Color.posOnSurfaceVariantLowest)
            .multilineTextAlignment(.center)
            .padding(.top, POSSpacing.xSmall)
    }
}

private extension PaymentsActionButtons {
    enum Localization {
        static let receipt = NSLocalizedString(
            "pos.totalsView.button.receipt",
            value: "Receipt",
            comment: "Button title to show receipt options on the payment success screen")

        static let emailReceipt = NSLocalizedString(
            "pos.totalsView.button.emailReceipt",
            value: "Email receipt",
            comment: "Button title for the email receipt button on the payment success screen")

        static let printerHint = NSLocalizedString(
            "pos.totalsView.printerHint",
            value: "Want to print receipts? Set up a printer in Settings.",
            comment: "Hint shown on the payment success screen when no printer is connected")
    }
}

#if DEBUG
#Preview("No printer") {
    PaymentsActionButtons(
        successAction: PaymentFlowAction(
            title: "New order",
            action: {},
            analyticsEvent: nil),
        printerConnectionState: .disconnected,
        isShowingReceiptModal: .constant(false),
        isShowingSendReceiptView: .constant(false))
}

#Preview("Printer connected") {
    PaymentsActionButtons(
        successAction: PaymentFlowAction(
            title: "New order",
            action: {},
            analyticsEvent: nil),
        printerConnectionState: .connected,
        isShowingReceiptModal: .constant(false),
        isShowingSendReceiptView: .constant(false))
}
#endif
