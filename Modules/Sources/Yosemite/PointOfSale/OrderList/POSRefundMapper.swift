import Foundation
import struct NetworkingCore.Refund

struct POSRefundMapper {
    func map(refund: NetworkingCore.Refund) -> POSRefund {
        let refundItems = refund.items.map { item in
            let refundedItemID = item.refundedItemID.flatMap { Int64($0) }
            return POSRefundItem(refundedItemID: refundedItemID, quantity: item.quantity)
        }
        return POSRefund(items: refundItems)
    }
}
