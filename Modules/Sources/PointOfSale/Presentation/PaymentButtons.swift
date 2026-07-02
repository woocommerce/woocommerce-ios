import SwiftUI

struct PaymentsActionButtons: View {
    let successAction: PaymentFlowAction
    let showsPrintReceipt: Bool
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
            AnyLayout(HStackLayout(spacing: Constants.receiptButtonRowSpacing))
        } else {
            AnyLayout(VStackLayout(spacing: Constants.receiptButtonRowSpacing))
        }
    }

    var sendReceiptButton: some View {
        Button(action: {
            analytics.track(.receiptEmailTapped)
            router.pushEmailReceipt()
        }, label: {
            HStack(spacing: Constants.buttonSpacing) {
                Text(Localization.sendReceipt)
            }
        })
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        .frame(maxWidth: .infinity)
    }

    var printReceiptButton: some View {
        Button(action: {}, label: {
            HStack(spacing: Constants.buttonSpacing) {
                Text(Localization.printReceipt)
            }
        })
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        .frame(maxWidth: .infinity)
    }

    var successButton: some View {
        Button(action: {
            if let event = successAction.analyticsEvent {
                analytics.track(event)
            }
            successAction.action()
        }, label: {
            HStack(spacing: Constants.buttonSpacing) {
                Text(successAction.title)
            }
        })
        .buttonStyle(POSFilledButtonStyle(size: .normal))
        .accessibilityIdentifier("pos-new-order-button")
    }
}


private extension PaymentsActionButtons {
    enum Constants {
        static let buttonSpacing: CGFloat = POSSpacing.medium
        static let receiptButtonRowSpacing: CGFloat = POSSpacing.small
    }

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
        showsPrintReceipt: true)
    .environment(\.horizontalSizeClass, .regular)
}

#Preview("Compact width") {
    PaymentsActionButtons(
        successAction: PaymentFlowAction(
            title: "New order",
            action: {},
            analyticsEvent: nil),
        showsPrintReceipt: true)
    .environment(\.horizontalSizeClass, .compact)
}
#endif
