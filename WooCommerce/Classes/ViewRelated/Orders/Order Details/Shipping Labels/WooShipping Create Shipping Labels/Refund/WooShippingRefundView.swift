import SwiftUI

struct WooShippingRefundView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("")
            }
        }
    }
}

private extension WooShippingRefundView {
    enum Localization {
        static let description = NSLocalizedString(
            "wooShippingRefundView.description",
            value: "Request a refund for your unused shipping label. " +
            "The refund process for the shipping label will begin immediately and " +
            "is typically completed within 14 business days.",
            comment: "Description on the Request shipping label refund view"
        )
        static let purchaseDate = NSLocalizedString(
            "wooShippingRefundView.purchaseDate",
            value: "Purchase date: %1$@",
            comment: "Purchase date label on the Request shipping label refund view. " +
            "The placeholder is the date of the purchase. Reads as: 'Purchase date: Feb 19, 2025'"
        )
        static let refundAmount = NSLocalizedString(
            "wooShippingRefundView.refundAmount",
            value: "Amount eligible for refund: %1$@",
            comment: "Refund amount label on the Request shipping label refund view. " +
            "The placeholder is the amount to be refunded. Reads as: 'Amount eligible for refund: $11.33'"
        )
        static let note = NSLocalizedString(
            "wooShippingRefundView.note",
            value: "Please note that this refund request applies only to the unused " +
            "shipping label and will not affect the order itself.",
            comment: "Note on the Request shipping label refund view"
        )
    }
}

#Preview {
    WooShippingRefundView()
}
