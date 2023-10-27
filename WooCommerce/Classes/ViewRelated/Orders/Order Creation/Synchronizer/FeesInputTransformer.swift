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

    /// Updates a fee into an existing order. If the fee is not there, it returns the order as it is.
    ///
    static func update(input: OrderFeeLine, on order: Order) -> Order {
        guard let index = order.fees.firstIndex(where: { $0.feeID == input.feeID }) else {
            return order
        }

        var updatedLines = order.fees
        updatedLines[index] = input

        return order.copy(fees: updatedLines)
    }

    /// Removes a fee line input from an existing order.
    /// If the order does not have that fee added it does nothing
    ///
    static func remove(input: OrderFeeLine, from order: Order) -> Order {
        let updatedLines = order.fees.map { line -> OrderFeeLine in
            if line.feeID == input.feeID {
                return OrderFactory.deletedFeeLine(line)
            }
            return line
        }
        return order.copy(fees: updatedLines)
    }
}
