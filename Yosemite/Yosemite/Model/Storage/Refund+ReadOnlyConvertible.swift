import Foundation
import Storage


// MARK: - Storage.Refund: ReadOnlyConvertible
//
extension Storage.Refund: ReadOnlyConvertible {

    /// Updates the Storage.Refund with the ReadOnly.
    ///
    public func update(with fullRefund: Yosemite.Refund) {
        refundID = Int64(fullRefund.refundID)
        orderID = Int64(fullRefund.orderID)
        siteID = Int64(fullRefund.siteID)
        dateCreated = fullRefund.dateCreated
        amount = fullRefund.amount
        reason = fullRefund.reason
        byUserID = Int64(fullRefund.refundedByUserID)

        if let automated = fullRefund.isAutomated {
            isAutomated = automated
        }

        if let createRefund = fullRefund.createAutomated {
            createAutomated = createRefund
        }
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.Refund {
        let orderItems = items?.map { $0.toReadOnly() } ?? [Yosemite.OrderItemRefund]()

        return Refund(refundID: Int64(refundID),
                      orderID: Int64(orderID),
                      siteID: Int64(siteID),
                      dateCreated: dateCreated ?? Date(),
                      amount: amount ?? "",
                      reason: reason ?? "",
                      refundedByUserID: Int64(byUserID),
                      isAutomated: isAutomated,
                      createAutomated: createAutomated,
                      items: orderItems)
    }
}
