import SwiftUI

struct PaymentsActionButtons: View {
    @Environment(\.posMetrics) private var metrics
    let successAction: PaymentFlowAction
    let showsPrintReceipt: Bool
    var printButtonState: POSButtonState = .idle
    let printReceiptAction: () -> Void
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posNavigationRouter) private var router
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ZStack {
            VStack {
                successButton
                receiptButtons
            }
        }
    }

    /// Email and Print sit side by side on regular width, and stack on compact width or at
    /// accessibility text sizes, where two buttons in a row would be too cramped.
    private var usesSideBySideReceiptButtons: Bool {
        showsPrintReceipt && horizontalSizeClass != .compact && !dynamicTypeSize.isAccessibilitySize
    }
}

private extension PaymentsActionButtons {
    var receiptButtons: some View {
        receiptButtonLayout {
            sendReceiptButton
            if showsPrintReceipt {
                printReceiptButton
            }
        }
    }

    var receiptButtonLayout: AnyLayout {
        if usesSideBySideReceiptButtons {
            AnyLayout(HStackLayout(spacing: metrics.spacing.small))
        } else {
            AnyLayout(VStackLayout(spacing: metrics.spacing.small))
        }
    }

    var sendReceiptButton: some View {
        Button(action: {
            analytics.track(.receiptEmailTapped)
            router.pushEmailReceipt()
        }, label: {
            HStack(spacing: metrics.spacing.medium) {
                Text(Localization.sendReceipt)
            }
        })
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("pos-email-receipt-button")
    }

    var printReceiptButton: some View {
        Button(action: printReceiptAction, label: {
            HStack(spacing: metrics.spacing.medium) {
                Text(Localization.printReceipt)
            }
        })
        .buttonStyle(POSOutlinedButtonStyle(size: .normal, state: printButtonState))
        .disabled(printButtonState != .idle)
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("pos-print-receipt-button")
    }

    var successButton: some View {
        Button(action: {
            if let event = successAction.analyticsEvent {
                analytics.track(event)
            }
            successAction.action()
        }, label: {
            HStack(spacing: metrics.spacing.medium) {
                Text(successAction.title)
            }
        })
        .buttonStyle(POSFilledButtonStyle(size: .normal))
        .accessibilityIdentifier("pos-new-order-button")
    }
}

private extension PaymentsActionButtons {
    enum Localization {
        static let sendReceipt = NSLocalizedString(
            "pos.totalsView.button.sendReceipt",
            value: "Email receipt",
            comment: "Button title for the receipt button")

        static let printReceipt = NSLocalizedString(
            "pos.paymentSuccess.button.printReceipt",
            value: "Print receipt",
            comment: "Button title on the Point of Sale payment success screen for printing a receipt for the completed order.")
    }
}

#if DEBUG
#Preview("Regular width") {
    PaymentsActionButtons(
        successAction: PaymentFlowAction(
            title: "New order",
            action: {},
            analyticsEvent: nil),
        showsPrintReceipt: true,
        printReceiptAction: {})
    .environment(\.horizontalSizeClass, .regular)
}

#Preview("Compact width") {
    PaymentsActionButtons(
        successAction: PaymentFlowAction(
            title: "New order",
            action: {},
            analyticsEvent: nil),
        showsPrintReceipt: true,
        printReceiptAction: {})
    .environment(\.horizontalSizeClass, .compact)
}
#endif
