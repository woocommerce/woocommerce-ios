import Foundation
import Yosemite

/// Helper to updates an `order` given an `ShippingLine` input type.
///
struct ShippingInputTransformer {

    /// Adds, deletes, or updates a shipping line input into an existing order.
    ///
    static func update(input: ShippingLine?, on order: Order) -> Order {
        // If input is `nil`, then we remove any existing shipping line.
        // We remove a shipping like by setting its `methodID` to nil.
        guard let input = input else {
            let linesToRemove = order.shippingLines.map { $0.copy(methodID: .some(nil), total: "0") }
            return order.copy(shippingTotal: "0", shippingLines: linesToRemove)
        }

        // If there is no existing shipping lines, we insert the input one.
        guard let existingShippingLine = order.shippingLines.first else {
            return order.copy(shippingTotal: input.total, shippingLines: [input])
        }

        // Since we only support one shipping line, if we find one, we update our input with the existing `shippingID`.
        let updatedShippingLine = input.copy(shippingID: existingShippingLine.shippingID)
        return order.copy(shippingTotal: updatedShippingLine.total, shippingLines: [updatedShippingLine])
    }
}
