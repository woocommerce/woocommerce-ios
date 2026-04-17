import SwiftUI

struct POSReceiptOptionsModal: View {
    @Binding var isPresented: Bool
    @Binding var isShowingSendReceiptView: Bool
    let onPrintReceipt: () -> Void
    @Environment(\.posAnalytics) private var analytics

    var body: some View {
        VStack(spacing: POSSpacing.xxLarge) {
            PointOfSaleModalHeader(
                isPresented: $isPresented,
                title: .constant(AttributedString(Localization.title)))

            VStack(spacing: POSSpacing.small) {
                emailButton
                printButton
            }
        }
        .padding(POSPadding.xxLarge)
        .background(Color.posSurfaceBright)
        .frame(width: Constants.modalWidth)
    }
}

private extension POSReceiptOptionsModal {
    var emailButton: some View {
        Button(action: {
            analytics.track(.receiptEmailTapped)
            isPresented = false
            isShowingSendReceiptView = true
        }, label: {
            Text(Localization.email)
        })
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
    }

    var printButton: some View {
        Button(action: {
            analytics.track(.receiptPrintTapped)
            isPresented = false
            onPrintReceipt()
        }, label: {
            Text(Localization.print)
        })
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
    }
}

private extension POSReceiptOptionsModal {
    enum Constants {
        static let modalWidth: CGFloat = 896
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pos.receiptOptionsModal.title",
            value: "How would you like to provide the receipt?",
            comment: "Title question for the receipt options modal on the payment success screen")

        static let email = NSLocalizedString(
            "pos.receiptOptionsModal.button.email",
            value: "Email",
            comment: "Button title to email a receipt from the receipt options modal")

        static let print = NSLocalizedString(
            "pos.receiptOptionsModal.button.print",
            value: "Print",
            comment: "Button title to print a receipt from the receipt options modal")
    }
}

#if DEBUG
#Preview {
    POSReceiptOptionsModal(
        isPresented: .constant(true),
        isShowingSendReceiptView: .constant(false),
        onPrintReceipt: { })
}
#endif
