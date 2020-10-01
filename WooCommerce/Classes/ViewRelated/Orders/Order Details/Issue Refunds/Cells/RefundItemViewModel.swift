import Foundation

/// Represents an order item to be refunded. Meant to be rendered by `RefundItemTableViewCell`
///
struct RefundItemViewModel {
    let productImage: URL?
    let productTitle: String
    let productQuantityAndPrice: String
    let quantityToRefund: String
}
