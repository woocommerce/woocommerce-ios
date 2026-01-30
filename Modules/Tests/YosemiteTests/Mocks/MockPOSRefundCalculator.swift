import Foundation
@testable import Yosemite

final class MockPOSRefundCalculator: POSRefundCalculating {
    private(set) var spyOrderID: Int64?
    private(set) var spySelectedItems: [POSRefundableItem]?
    private(set) var spyReason: String?

    var stubRefundRequest: POSRefundRequest?

    func buildRefundRequest(
        orderID: Int64,
        selectedItems: [POSRefundableItem],
        reason: String?
    ) -> POSRefundRequest {
        spyOrderID = orderID
        spySelectedItems = selectedItems
        spyReason = reason

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
}
