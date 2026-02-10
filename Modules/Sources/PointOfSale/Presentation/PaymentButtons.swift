import SwiftUI

struct PaymentsActionButtons: View {
    let successAction: PaymentFlowAction
    @Environment(\.posAnalytics) private var analytics
    @Binding var isShowingSendReceiptView: Bool

    var body: some View {
        ZStack {
            VStack {
                successButton
                sendReceiptButton
            }
        }
    }
}

private extension PaymentsActionButtons {
    var sendReceiptButton: some View {
        Button(action: {
            analytics.track(.receiptEmailTapped)
            isShowingSendReceiptView = true
        }, label: {
            HStack(spacing: Constants.buttonSpacing) {
                Text(Localization.sendReceipt)
            }
        })
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
    }

    var successButton: some View {
        Button(action: {
            analytics.track(.pointOfSaleCreateNewOrderTapped)
            successAction.action()
        }, label: {
            HStack(spacing: Constants.buttonSpacing) {
                Text(successAction.title)
            }
        })
        .buttonStyle(POSFilledButtonStyle(size: .normal))
    }
}


private extension PaymentsActionButtons {
    enum Constants {
        static let buttonSpacing: CGFloat = POSSpacing.medium
    }

    enum Localization {
        static let sendReceipt = NSLocalizedString(
            "pos.totalsView.button.sendReceipt",
            value: "Email receipt",
            comment: "Button title for the receipt button")
    }
}

#if DEBUG
#Preview {
    PaymentsActionButtons(
        successAction: PaymentFlowAction(
            title: "New order",
            action: {}),
        isShowingSendReceiptView: .constant(false))
}
#endif
