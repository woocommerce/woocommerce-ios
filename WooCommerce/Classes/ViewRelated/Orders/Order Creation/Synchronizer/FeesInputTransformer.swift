import Foundation
import Yosemite

/// Helper to update an `order` given an `OrderFeeLine` input type.
///
struct FeesInputTransformer {

    /// Adds, deletes, or updates a fee line input into an existing order.
    ///
    static func update(input: OrderFeeLine?, on order: Order) -> Order {
        // If input is `nil`, then we remove any existing fee line.
        // We remove a fee line by setting its `name` to nil.
        guard let input = input else {
            let linesToRemove = order.fees.map { $0.copy(name: .some(nil), total: "0") }
            return order.copy(fees: linesToRemove)
        }

        // If there is no existing fee lines, we insert the input one.
        guard let existingFeeLine = order.fees.first else {
            return order.copy(fees: [input])
        }

        // Since we only support one fee line, if we find one, we update our input with the existing `feeID`.
        let updatedFeeLine = input.copy(feeID: existingFeeLine.feeID)
        return order.copy(fees: [updatedFeeLine])
    }
}
