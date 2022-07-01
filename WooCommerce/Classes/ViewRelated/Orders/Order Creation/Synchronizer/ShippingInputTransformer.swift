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
            let updatedLines = order.shippingLines.enumerated().map { index, line -> ShippingLine in
                if index == 0 {
                    return OrderFactory.deletedShippingLine(line)
                }
                return line
            }
            return order.copy(shippingTotal: calculateTotals(from: updatedLines), shippingLines: updatedLines)
        }

        // If there is no existing shipping lines, we insert the input one.
        guard let existingShippingLine = order.shippingLines.first else {
            return order.copy(shippingTotal: input.total, shippingLines: [input])
        }

        // Since we only support one shipping line, if we find one, we update the existing with the new input values.
        var updatedLines = order.shippingLines
        let updatedShippingLine = existingShippingLine.copy(methodTitle: input.methodTitle, total: input.total)
        updatedLines[0] = updatedShippingLine

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
