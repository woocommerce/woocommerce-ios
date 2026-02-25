import Foundation

public struct BookingOrderRefund: Hashable {
    public let refundID: Int64
    public let reason: String?
    public let total: String

    public init(refundID: Int64, reason: String?, total: String) {
        self.refundID = refundID
        self.reason = reason
        self.total = total
    }
}
