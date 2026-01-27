import Foundation
import struct NetworkingCore.Refund

struct POSRefundMapper {
    func map(refund: NetworkingCore.Refund) -> POSRefund {
        let refundItems = refund.items.map { POSRefundItem(quantity: $0.quantity) }
        return POSRefund(items: refundItems)
    }
}
