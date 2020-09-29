import Foundation

/// Represents shipping details for an order to be refunded. Meant to be rendered by `RefundShippingDetailsTableViewCell`
///
struct RefundShippingDetailsViewModel {
    let carrierRate: String
    let carrierCost: String
    let shippingTax: String
    let shippingSubtotal: String
    let shippingTotal: String
}
