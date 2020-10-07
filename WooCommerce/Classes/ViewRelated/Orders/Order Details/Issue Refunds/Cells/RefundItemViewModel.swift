import Foundation
import Yosemite

/// Represents an order item to be refunded. Meant to be rendered by `RefundItemTableViewCell`
///
struct RefundItemViewModel {
    let productImage: String?
    let productTitle: String
    let productQuantityAndPrice: String
    let quantityToRefund: String
}
