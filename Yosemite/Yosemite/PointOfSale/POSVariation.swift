import Foundation

public struct POSVariation: OrderSyncProductVariationTypeProtocol, Equatable, Hashable, Identifiable {
    // Identifiable & POSOrderableItem
    public let id: UUID

    // POSOrderableItem
    public let name: String
    public let formattedPrice: String
    public var productImageSource: String?

    // OrderSyncProductVariationTypeProtocol
    public let productID: Int64
    public let productVariationID: Int64
    public let price: String

    public init(id: UUID, name: String, formattedPrice: String, price: String, productImageSource: String? = nil, productID: Int64, variationID: Int64) {
        self.id = id
        self.name = name
        self.formattedPrice = formattedPrice
        self.price = price
        self.productImageSource = productImageSource
        self.productID = productID
        self.productVariationID = variationID
    }
}

extension POSVariation: POSOrderableItem {
    public func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput {
        OrderSyncProductInput(product: .variation(self), quantity: quantity)
    }

    public func matches(orderItem: OrderItem) -> Bool {
        productID == orderItem.productID && productVariationID == orderItem.variationID
    }
}
