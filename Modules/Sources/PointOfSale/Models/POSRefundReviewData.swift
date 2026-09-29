import Foundation

/// Data model for displaying the refund review screen.
/// Contains pre-calculated and formatted values ready for display.
public struct POSRefundReviewData: Equatable {

    /// Which side calculated the totals on this screen. Reported on the refund processing events
    /// so success and failure rates can be compared between the two flows during the
    /// server-refunds rollout. Keep the raw values in step with Android's `refund_flow` property.
    public enum CalculationFlow: String {
        case local
        case serverComputed = "server_computed"
    }

    let itemsCount: Int
    let formattedItemsSubtotal: String
    let formattedTax: String
    let formattedRefundTotal: String
    let paymentMethodDescription: String
    let customerEmail: String?
    var refundReason: String?
    let isFullRefund: Bool
    let calculationFlow: CalculationFlow

    public init(itemsCount: Int,
                formattedItemsSubtotal: String,
                formattedTax: String,
                formattedRefundTotal: String,
                paymentMethodDescription: String,
                customerEmail: String?,
                refundReason: String?,
                isFullRefund: Bool,
                calculationFlow: CalculationFlow) {
        self.itemsCount = itemsCount
        self.formattedItemsSubtotal = formattedItemsSubtotal
        self.formattedTax = formattedTax
        self.formattedRefundTotal = formattedRefundTotal
        self.paymentMethodDescription = paymentMethodDescription
        self.customerEmail = customerEmail
        self.refundReason = refundReason
        self.isFullRefund = isFullRefund
        self.calculationFlow = calculationFlow
    }
}
