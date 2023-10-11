import Foundation
import Yosemite

/// Helper to update an `order` given an `OrderFeeLine` input type.
///
struct FeesInputTransformer {
    /// Adds a fee into an existing order.
    ///
    static func append(input: OrderFeeLine, on order: Order) -> Order {
        guard !order.fees.contains(input) else {
            return order
        }

        return order.copy(fees: order.fees + [input])
    }

    /// Removes a fee line input from an existing order.
    /// If the order does not have that fee added it does nothing
    ///
    static func remove(input: OrderFeeLine, from order: Order) -> Order {
        var updatedFeeLines = order.fees
        updatedFeeLines.removeAll(where: { $0.feeID == input.feeID })

        return order.copy(fees: updatedFeeLines)
    }

    /// Adds a fee into an existing order, removing the rest.
    ///
    static func set(input: OrderFeeLine, on order: Order) -> Order {
        guard !order.fees.contains(input) else {
            return order
        }

        return order.copy(fees: [input])
    }
}
