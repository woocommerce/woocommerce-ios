import Foundation

/// Data model for displaying the refund review screen.
/// Contains pre-calculated and formatted values ready for display.
struct POSRefundReviewData: Equatable {
    let itemsCount: Int
    let formattedItemsSubtotal: String
    let formattedTax: String
    let formattedRefundTotal: String
    let paymentMethodDescription: String
    let customerEmail: String?
    var refundReason: String?
    let isFullRefund: Bool
}
