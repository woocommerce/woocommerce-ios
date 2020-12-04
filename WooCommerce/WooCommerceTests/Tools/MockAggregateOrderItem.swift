import Foundation
@testable import WooCommerce

/// Generates mock `AggregateOrderItem`
///
public struct MockAggregateOrderItem {
    /// Consider setting a subset of properties using `.copy`.
    public static func emptyItem() -> AggregateOrderItem {
        .init(productID: 0,
              variationID: 0,
              name: "",
              price: nil,
              quantity: 0,
              sku: nil,
              total: nil,
              attributes: [])
    }
}
