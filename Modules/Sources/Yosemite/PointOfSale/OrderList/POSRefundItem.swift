import Foundation

public struct POSRefundItem: Identifiable, Equatable, Hashable {
    public let id: UUID

    /// The original order line item ID that was refunded.
    /// This matches the `itemID` on `POSOrderItem`, or the fee `id` on `POSOrderCustomAmount`.
    public let refundedItemID: Int64?
    public let quantity: Decimal
    public let name: String
    public let formattedPrice: String
    public let formattedTotal: String
    public let imageSrc: String?
    /// `true` when the underlying refunded line was a custom amount / fee, not a product.
    /// Lump-sum lines have no quantity / unit-level breakdown.
    public let isLumpSum: Bool

    public init(refundedItemID: Int64?,
                quantity: Decimal,
                name: String,
                formattedPrice: String,
                formattedTotal: String,
                imageSrc: String?,
                isLumpSum: Bool = false,
                id: UUID = UUID()) {
        self.id = id
        self.refundedItemID = refundedItemID
        self.quantity = quantity
        self.name = name
        self.formattedPrice = formattedPrice
        self.formattedTotal = formattedTotal
        self.imageSrc = imageSrc
        self.isLumpSum = isLumpSum
    }

    public static func == (lhs: POSRefundItem, rhs: POSRefundItem) -> Bool {
        lhs.refundedItemID == rhs.refundedItemID &&
        lhs.quantity == rhs.quantity &&
        lhs.name == rhs.name &&
        lhs.formattedPrice == rhs.formattedPrice &&
        lhs.formattedTotal == rhs.formattedTotal &&
        lhs.imageSrc == rhs.imageSrc &&
        lhs.isLumpSum == rhs.isLumpSum
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(refundedItemID)
        hasher.combine(quantity)
        hasher.combine(name)
        hasher.combine(formattedPrice)
        hasher.combine(formattedTotal)
        hasher.combine(imageSrc)
        hasher.combine(isLumpSum)
    }
}
