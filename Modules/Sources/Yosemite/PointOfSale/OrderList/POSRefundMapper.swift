import Foundation
import struct NetworkingCore.Refund

struct POSRefundMapper {
    func map(refund: NetworkingCore.Refund) -> POSRefund {
        let refundItems = refund.items.map { POSRefundItem(productID: $0.productID, variationID: $0.variationID, quantity: $0.quantity) }

        return POSRefund(items: refundItems)
    }
}
