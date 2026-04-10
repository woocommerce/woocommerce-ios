import Foundation
import struct NetworkingCore.OrderRefundCondensed
import class WooFoundationCore.CurrencyFormatter

public struct POSOrderRefund: Equatable, Hashable, Identifiable {
    public var id: Int64 { refundID }

    public let refundID: Int64
    public let formattedTotal: String
    public let reason: String?
    public let dateCreated: Date?
    public let items: [POSRefundItem]
    public let formattedItemsSubtotal: String
    public let formattedTax: String
    public let itemCount: Int

    public init(refundID: Int64,
                formattedTotal: String,
                reason: String? = nil,
                dateCreated: Date? = nil,
                items: [POSRefundItem] = [],
                formattedItemsSubtotal: String = "",
                formattedTax: String = "",
                itemCount: Int = 0) {
        self.refundID = refundID
        self.formattedTotal = formattedTotal
        self.reason = reason
        self.dateCreated = dateCreated
        self.items = items
        self.formattedItemsSubtotal = formattedItemsSubtotal
        self.formattedTax = formattedTax
        self.itemCount = itemCount
    }
}
