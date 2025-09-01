import Foundation
import struct NetworkingCore.OrderRefundCondensed

public struct POSOrderRefund: Equatable, Hashable {
    public let refundID: Int64
    public let total: String
    public let reason: String?

    public init(refundID: Int64,
                total: String,
                reason: String? = nil) {
        self.refundID = refundID
        self.total = total
        self.reason = reason
    }
}

// MARK: - Conversion from NetworkingCore.OrderRefundCondensed
public extension POSOrderRefund {
    init(from refund: OrderRefundCondensed) {
        self.init(
            refundID: refund.refundID,
            total: refund.total,
            reason: refund.reason
        )
    }
}
