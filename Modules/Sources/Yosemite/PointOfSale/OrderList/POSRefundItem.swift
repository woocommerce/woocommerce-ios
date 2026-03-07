import Foundation

public struct POSRefundItem: Equatable, Hashable {
    /// The original order line item ID that was refunded.
    /// This matches the `itemID` on `POSOrderItem`.
    public let refundedItemID: Int64?
    public let quantity: Decimal
    public let name: String
    public let formattedPrice: String
    public let formattedTotal: String
    public let imageSrc: String?

    public init(refundedItemID: Int64?,
                quantity: Decimal,
                name: String = "",
                formattedPrice: String = "",
                formattedTotal: String = "",
                imageSrc: String? = nil) {
        self.refundedItemID = refundedItemID
        self.quantity = quantity
        self.name = name
        self.formattedPrice = formattedPrice
        self.formattedTotal = formattedTotal
        self.imageSrc = imageSrc
    }
}
