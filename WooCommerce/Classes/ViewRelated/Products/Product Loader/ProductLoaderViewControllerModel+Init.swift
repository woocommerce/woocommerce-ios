import struct Yosemite.OrderItem
import struct Yosemite.OrderItemRefund
import struct Yosemite.TopEarnerStatsItem

/// Contains initializers for `ProductLoaderViewController.Model` from different types.
extension ProductLoaderViewController.Model {
    init(orderItem: OrderItem) {
        self = orderItem.productLoaderModel
    }

    init(orderItemRefund: OrderItemRefund) {
        self = orderItemRefund.productLoaderModel
    }

    init(aggregateOrderItem: AggregateOrderItem) {
        self = aggregateOrderItem.productLoaderModel
    }

    init(topEarnerStatsItem: TopEarnerStatsItem) {
        self = .product(productID: topEarnerStatsItem.productID)
    }
}

private protocol ProductOrVariationIDContaining {
    var productID: Int64 { get }
    var variationID: Int64 { get }
}

private extension ProductOrVariationIDContaining {
    var productLoaderModel: ProductLoaderViewController.Model {
        if variationID == 0 {
            return .product(productID: productID)
        } else {
            return .productVariation(productID: productID, variationID: variationID)
        }
    }
}

extension OrderItem: ProductOrVariationIDContaining {}
extension OrderItemRefund: ProductOrVariationIDContaining {}
extension AggregateOrderItem: ProductOrVariationIDContaining {}
