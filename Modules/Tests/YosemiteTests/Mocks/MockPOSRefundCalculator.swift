import Foundation
@testable import Yosemite

final class MockPOSRefundCalculator: POSRefundCalculating {
    private(set) var spyOrderID: Int64?
    private(set) var spySelectedItems: [POSRefundableItem]?
    private(set) var spyReason: String?
    private(set) var spyNumberOfDecimals: Int?

    var stubRefundRequest: POSRefundRequest?
    var stubRefundAmounts: POSRefundAmounts?

    func buildRefundRequest(
        orderID: Int64,
        selectedItems: [POSRefundableItem],
        reason: String?,
        numberOfDecimals: Int
    ) -> POSRefundRequest {
        spyOrderID = orderID
        spySelectedItems = selectedItems
        spyReason = reason
        spyNumberOfDecimals = numberOfDecimals

        if let stub = stubRefundRequest {
            return stub
        }

        return POSRefundRequest(
            orderID: orderID,
            amount: selectedItems.reduce(Decimal.zero) { $0 + $1.price },
            reason: reason,
            items: []
        )
    }

    func calculateRefundAmounts(for items: [POSRefundableItem], numberOfDecimals: Int) -> POSRefundAmounts {
        spySelectedItems = items
        spyNumberOfDecimals = numberOfDecimals

        if let stub = stubRefundAmounts {
            return stub
        }

        let subtotal = items.reduce(Decimal.zero) { $0 + $1.price }
        let tax = items.reduce(Decimal.zero) { $0 + $1.totalTax }
        return POSRefundAmounts(subtotal: subtotal, tax: tax)
    }
}
