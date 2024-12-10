import Foundation

public struct POSVariation: Equatable, Hashable, Identifiable { //POSOrderableItem, OrderSyncProductTypeProtocol, Equatable, Hashable, Identifiable {
    //    // POSOrderableItem
    public let id: UUID
    public let name: String
    public let formattedPrice: String
    public var productImageSource: String?
    //
    //    // OrderSyncProductTypeProtocol
    public let productID: Int64
    public let variationID: Int64
    //    public let price: String
    public let productType: ProductType = .variable
    public let bundledItems: [ProductBundleItem] = []

    public init(id: UUID, name: String, formattedPrice: String, productImageSource: String? = nil, productID: Int64, variationID: Int64) {
        self.id = id
        self.name = name
        self.formattedPrice = formattedPrice
        self.productImageSource = productImageSource
        self.productID = productID
        self.variationID = variationID
    }
}
//
//    public init(id: UUID, name: String, formattedPrice: String, productImageSource: String? = nil, productID: Int64, variationID: Int64, price: String) {
//        self.id = id
//        self.name = name
//        self.formattedPrice = formattedPrice
//        self.productImageSource = productImageSource
//        self.productID = productID
//        self.variationID = variationID
//        self.price = price
//    }
//}
//
//extension POSVariation {
//    public func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput {
//        OrderSyncProductInput(product: .variation(self), quantity: quantity)
//    }
//
//    public func matches(orderItem: OrderItem) -> Bool {
//        // TODO: https://github.com/woocommerce/woocommerce-ios/pull/13328/files#r1687631533
//        // - we should also add a logic to compare prices
//        // - but we should be aware of the fact that some
//        // products already have tax in the price
//        return productID == orderItem.productID && variationID == orderItem.variationID
//    }
//}
