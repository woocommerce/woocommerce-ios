import Foundation
import Yosemite

/// Helper to updates an `order` given an `ShippingLine` input type.
///
struct ShippingInputTransformer {

    /// Adds or updates a shipping line input into an existing order.
    ///
    static func update(input: ShippingLine, on order: Order) -> Order {
        var updatedLines = order.shippingLines

        // If the order contains the shipping line, we update it with the new input values.
        if let index = updatedLines.firstIndex(where: { $0.shippingID == input.shippingID }) {
            let updatedShippingLine = updatedLines[index].copy(methodTitle: input.methodTitle, methodID: input.methodID, total: input.total)
            updatedLines[index] = updatedShippingLine
        }
        // Otherwise, we insert the input as a new shipping line on the order.
        else {
            let newShippingLine = input.methodID?.isNotEmpty == true ? input : OrderFactory.noMethodShippingLine(input)
            updatedLines.append(newShippingLine)
        }

        return order.copy(shippingTotal: calculateTotals(from: updatedLines), shippingLines: updatedLines)
    }

    /// Deletes a shipping line input from an existing order.
    ///
    static func remove(input: ShippingLine, from order: Order) -> Order {
        var updatedLines = order.shippingLines

        // Find index of the shipping line to delete.
        guard let index = updatedLines.firstIndex(where: { $0.shippingID == input.shippingID }) else {
            return order
        }

        // Replace the existing shipping line with the deleted shipping line.
        let deletedShippingLine = OrderFactory.deletedShippingLine(input)
        updatedLines[index] = deletedShippingLine

        return order.copy(shippingTotal: calculateTotals(from: updatedLines), shippingLines: updatedLines)
    }

    /// Sum totals based on the provided shipping lines values.
    ///
    private static func calculateTotals(from shippingLines: [ShippingLine]) -> String {
        let total = shippingLines.reduce(0) { accumulator, shippingLine in
            accumulator + (Double(shippingLine.total) ?? .zero)
        }
        return "\(total)"
    }
}
