import Foundation
import struct NetworkingCore.OrderRefundCondensed
import class WooFoundationCore.CurrencyFormatter

public struct POSOrderRefund: Equatable, Hashable {
    public let refundID: Int64
    public let total: String
    public let formattedTotal: String
    public let reason: String?

    public init(refundID: Int64,
                total: String,
                formattedTotal: String,
                reason: String? = nil) {
        self.refundID = refundID
        self.total = total
        self.formattedTotal = formattedTotal
        self.reason = reason
    }
}
