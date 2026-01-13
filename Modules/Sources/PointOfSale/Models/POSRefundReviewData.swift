import Foundation

/// Data model for displaying the refund review screen.
/// Contains pre-calculated and formatted values ready for display.
struct POSRefundReviewData: Equatable {
    let selectedItems: [POSRefundSelectableItem]
    let itemsCount: Int
    let formattedItemsSubtotal: String
    let formattedTax: String
    let formattedRefundTotal: String
    let paymentMethodDescription: String
    var refundReason: String?
}
