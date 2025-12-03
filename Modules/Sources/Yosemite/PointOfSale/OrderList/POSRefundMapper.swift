import Foundation
import struct NetworkingCore.Refund

struct POSRefundMapper {
    func map(order: NetworkingCore.Refund) -> POSRefund {
        POSRefund(items: [])
    }
}
