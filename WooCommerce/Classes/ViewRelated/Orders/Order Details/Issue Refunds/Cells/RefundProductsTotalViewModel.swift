import Foundation

/// Represents products cost details for an order to be refunded. Meant to be rendered by `RefundProductsTotalTableViewCell`
///
struct RefundProductsTotalViewModel {
    let productsTax: String
    let productsSubtotal: String
    let productsTotal: String
}
