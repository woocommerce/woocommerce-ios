import WooFoundation

public struct POSProduct: POSOrderableItem, OrderSyncProductTypeProtocol, Equatable {
    // POSOrderableItem
    public let id: UUID
    public let name: String
    public let formattedPrice: String
    public var productImageSource: String?

    // OrderSyncProductTypeProtocol
    public let productID: Int64
    public let price: String
    public let productType: ProductType = .simple
    public let bundledItems: [ProductBundleItem] = []

    public init(id: UUID, name: String, formattedPrice: String, productImageSource: String? = nil, productID: Int64, price: String) {
        self.id = id
        self.name = name
        self.formattedPrice = formattedPrice
        self.productImageSource = productImageSource
        self.productID = productID
        self.price = price
    }
}

extension POSProduct: Hashable {
    public func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput {
        OrderSyncProductInput(product: .product(self), quantity: quantity)
    }

    public func matches(orderItem: OrderItem) -> Bool {
        // TODO: https://github.com/woocommerce/woocommerce-ios/pull/13328/files#r1687631533
        // - we should also add a logic to compare prices
        // - but we should be aware of the fact that some
        // products already have tax in the price
        return productID == orderItem.productID
    }
}
