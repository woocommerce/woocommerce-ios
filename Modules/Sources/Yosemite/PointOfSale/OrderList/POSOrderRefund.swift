import Foundation
import struct NetworkingCore.OrderRefundCondensed
import class WooFoundationCore.CurrencyFormatter

public struct POSOrderRefund: Equatable, Hashable {
    public let refundID: Int64
    public let formattedTotal: String
    public let reason: String?
    public let dateCreated: Date?

    public init(refundID: Int64,
                formattedTotal: String,
                reason: String? = nil,
                dateCreated: Date? = nil) {
        self.refundID = refundID
        self.formattedTotal = formattedTotal
        self.reason = reason
        self.dateCreated = dateCreated
    }
}
