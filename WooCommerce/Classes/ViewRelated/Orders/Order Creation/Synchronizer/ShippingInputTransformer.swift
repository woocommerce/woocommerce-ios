import Foundation
import Yosemite

/// Helper to updates an `order` given an `ShippingLine` input type.
///
struct ShippingInputTransformer {

    /// Adds, deletes, or updates a shipping line input into an existing order.
    ///
    static func update(input: ShippingLine?, on order: Order) -> Order {
        // If input is `nil`, then we remove the first shipping line.
        // We remove a shipping like by setting its `methodID` to nil.
        guard let input = input else {
            guard let lineToRemove = order.shippingLines.first.map({ OrderFactory.deletedShippingLine($0) }) else {
                return order
            }
            return order.copy(shippingLines: [lineToRemove])
        }

        // If there is no existing shipping lines, we insert the input one.
        guard let existingShippingLine = order.shippingLines.first else {
            return order.copy(shippingTotal: input.total, shippingLines: [input])
        }

        // Since we only support one shipping line, if we find one, we update the existing with the new input values.
        let updatedShippingLine = existingShippingLine.copy(methodTitle: input.methodTitle, total: input.total)
        return order.copy(shippingTotal: updatedShippingLine.total, shippingLines: [updatedShippingLine])
    }
}
