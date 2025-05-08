import SwiftUI

/// View for requesting refund for a shipping label.
///
struct WooShippingRefundView: View {
    @Environment(\.dismiss) var dismiss

    let viewModel: WooShippingRefundViewModel

    var body: some View {
        ScrollableVStack(alignment: .leading, spacing: Layout.contentSpacing) {
            HStack {
                Button(Localization.cancelButton) {
                    dismiss()
                }
                Spacer()
            }

            Text(Localization.title)
                .font(.title2)
                .bold()
                .padding(.vertical, Layout.titleExtraPadding)

            Text(Localization.description)

            Text(Localization.purchaseDate).bold() +
            Text(" ") +
            Text(viewModel.formattedPurchaseDate)

            Text(Localization.refundAmount).bold() +
            Text(" ") +
            Text(viewModel.formattedRefundAmount)

            Text(Localization.note)
                .italic()
            Spacer()
        }
        .multilineTextAlignment(.leading)
        .safeAreaInset(edge: .bottom) {
            VStack {
                Button(String.localizedStringWithFormat(Localization.submitButton, "-" + viewModel.formattedRefundAmount)) {
                    viewModel.submitRefundRequest()
                }
                .buttonStyle(PrimaryLoadingButtonStyle(isLoading: false))
                .padding()
            }
            .background(Color(.systemBackground))
        }
    }
}

private extension WooShippingRefundView {
    enum Layout {
        static let contentSpacing = CGFloat(8)
        static let titleExtraPadding = CGFloat(16)
    }

    enum Localization {
        static let title = NSLocalizedString(
            "wooShippingRefundView.title",
            value: "Request a shipping label refund",
            comment: "title on the Request shipping label refund view"
        )
        static let description = NSLocalizedString(
            "wooShippingRefundView.description",
            value: "Request a refund for your unused shipping label. " +
            "The refund process for the shipping label will begin immediately and " +
            "is typically completed within 14 business days.",
            comment: "Description on the Request shipping label refund view"
        )
        static let purchaseDate = NSLocalizedString(
            "wooShippingRefundView.purchaseDate",
            value: "Purchase date:",
            comment: "Purchase date label on the Request shipping label refund view."
        )
        static let refundAmount = NSLocalizedString(
            "wooShippingRefundView.refundAmount",
            value: "Amount eligible for refund:",
            comment: "Refund amount label on the Request shipping label refund view."
        )
        static let note = NSLocalizedString(
            "wooShippingRefundView.note",
            value: "Please note that this refund request applies only to the unused " +
            "shipping label and will not affect the order itself.",
            comment: "Note on the Request shipping label refund view"
        )
        static let cancelButton = NSLocalizedString(
            "wooShippingRefundView.cancelButton",
            value: "Cancel",
            comment: "Button to dismiss the Request shipping label refund view"
        )
        static let submitButton = NSLocalizedString(
            "wooShippingRefundView.submitButton",
            value: "Refund Label (%1$@)",
            comment: "Button to submit refund request the Request shipping label refund view"
        )
    }
}

#Preview {
    WooShippingRefundView(viewModel: .init(refundableAmount: 11.33, purchaseDate: Date()))
}
