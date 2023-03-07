import Foundation
import Yosemite

/// Helper to update an `order` given an `OrderFeeLine` input type.
///
struct FeesInputTransformer {

    /// Adds, deletes, or updates a fee line input into an existing order.
    ///
    static func update(input: OrderFeeLine?, on order: Order) -> Order {
        // If input is `nil`, then we remove the first existing fee line.
        guard let input = input else {
            let updatedLines = order.fees.enumerated().map { index, line -> OrderFeeLine in
                if index == 0 {
                    return OrderFactory.deletedFeeLine(line)
                }
                return line
            }
            return order.copy(fees: updatedLines)
        }

        // If there is no existing fee lines, we insert the input one.
        guard let existingFeeLine = order.fees.first else {
            return order.copy(fees: [input])
        }

        // Since we only support one fee line, if we find one, we update the existing with the new input values.
        var updatedLines = order.fees
        let updatedFeeLine = existingFeeLine.copy(total: input.total)
        updatedLines[0] = updatedFeeLine

        return order.copy(fees: updatedLines)
    }
}
