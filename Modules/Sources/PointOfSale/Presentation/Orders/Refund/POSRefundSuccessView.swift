import SwiftUI

struct POSRefundSuccessView: View {
    let formattedRefundTotal: String
    let paymentMethodDescription: String
    let customerEmail: String?
    let onDone: () -> Void
    let onEmailReceipt: () -> Void
    let onClose: () -> Void

    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isViewLoaded: Bool = false

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            contentView
            buttonsSection
        }
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius(for: horizontalSizeClass)))
        .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding(for: horizontalSizeClass) * 2))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                isViewLoaded = true
            }
        }
    }
}

// MARK: - Subviews

private extension POSRefundSuccessView {
    var headerView: some View {
        HStack {
            Spacer()
            Button {
                onClose()
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var contentView: some View {
        VStack(spacing: POSSpacing.xLarge) {
            POSSuccessIcon()
                .scaleEffect(isViewLoaded ? 1 : 0)
                .opacity(isViewLoaded ? 1 : 0)

            VStack(spacing: POSSpacing.small) {
                Text(Localization.title)
                    .font(.posHeadingBold)
                    .foregroundColor(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)
                    .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                    .opacity(isViewLoaded ? 1 : 0)

                Text(String(format: Localization.messageFormat, formattedRefundTotal, paymentMethodDescription))
                    .font(.posBodyLargeRegular())
                    .foregroundColor(Color.posOnSurface)
                    .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                    .opacity(isViewLoaded ? 1 : 0)

                if let customerEmail, customerEmail.isNotEmpty {
                    Text(String(format: Localization.receiptSentFormat, customerEmail))
                        .font(.posBodyLargeRegular())
                        .foregroundColor(Color.posOnSurface)
                        .offset(y: isViewLoaded ? 0 : Constants.animationOffset)
                        .opacity(isViewLoaded ? 1 : 0)
                }
            }
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, POSPadding.xLarge)
        .padding(.bottom, POSSpacing.xLarge)
    }


    var buttonsSection: some View {
        VStack(spacing: POSSpacing.medium) {
            Button(Localization.doneButton, action: onDone)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

            Button(Localization.emailReceiptButton, action: onEmailReceipt)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .padding(POSPadding.xLarge)
        .offset(y: isViewLoaded ? 0 : -Constants.animationOffset)
        .opacity(isViewLoaded ? 1 : 0)
    }
}


// MARK: - Constants

private extension POSRefundSuccessView {
    enum Constants {
        static let animationOffset: CGFloat = 100
    }
}

// MARK: - Localization

private extension POSRefundSuccessView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.refundSuccessView.title",
            value: "Refund complete",
            comment: "Title shown when a refund has been successfully processed"
        )

        static let messageFormat = NSLocalizedString(
            "pos.refundSuccessView.messageFormat",
            value: "You refunded %1$@ %2$@.",
            comment: "Message shown after successful refund. %1$@ is the formatted amount, %2$@ is the payment method description."
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundSuccessView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on refund success screen"
        )

        static let doneButton = NSLocalizedString(
            "pos.refundSuccessView.doneButton",
            value: "Done",
            comment: "Button to dismiss the refund success screen"
        )

        static let emailReceiptButton = NSLocalizedString(
            "pos.refundSuccessView.emailReceiptButton",
            value: "Email receipt",
            comment: "Button to email a receipt for the refund"
        )

        static let receiptSentFormat = NSLocalizedString(
            "pos.refundSuccessView.receiptSent",
            value: "A receipt has been sent to %1$@.",
            comment: "Informational message shown on refund success screen when an email receipt is automatically sent. " +
            "%1$@ is a placeholder for the customer's email address."
        )
    }
}

#if DEBUG
#Preview("POSRefundSuccessView") {
    POSRefundSuccessView(
        formattedRefundTotal: "$132.60",
        paymentMethodDescription: "via payment card ••••1456",
        customerEmail: "test@example.com",
        onDone: {},
        onEmailReceipt: {},
        onClose: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
