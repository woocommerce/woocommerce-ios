import Foundation

/// Data model for displaying the refund review screen.
/// Contains pre-calculated and formatted values ready for display.
public struct POSRefundReviewData: Equatable {
    let itemsCount: Int
    let formattedItemsSubtotal: String
    let formattedTax: String
    let formattedRefundTotal: String
    let paymentMethodDescription: String
    let customerEmail: String?
    var refundReason: String?
    let isFullRefund: Bool

    public init(itemsCount: Int,
                formattedItemsSubtotal: String,
                formattedTax: String,
                formattedRefundTotal: String,
                paymentMethodDescription: String,
                customerEmail: String?,
                refundReason: String?,
                isFullRefund: Bool) {
        self.itemsCount = itemsCount
        self.formattedItemsSubtotal = formattedItemsSubtotal
        self.formattedTax = formattedTax
        self.formattedRefundTotal = formattedRefundTotal
        self.paymentMethodDescription = paymentMethodDescription
        self.customerEmail = customerEmail
        self.refundReason = refundReason
        self.isFullRefund = isFullRefund
    }
}
