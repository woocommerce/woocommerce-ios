import WooFoundation

struct POSProduct: POSOrderableItem, OrderSyncProductTypeProtocol {
    // POSOrderableItem
    let id: UUID
    let name: String
    let formattedPrice: String
    var productImageSource: String?

    // OrderSyncProductTypeProtocol
    let productID: Int64
    let price: String
    let productType: ProductType = .simple
    let bundledItems: [ProductBundleItem] = []
}

extension POSProduct {
    func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput {
        OrderSyncProductInput(product: .product(self), quantity: quantity)
    }

    func matches(orderItem: OrderItem) -> Bool {
        // TODO: https://github.com/woocommerce/woocommerce-ios/pull/13328/files#r1687631533
        // - we should also add a logic to compare prices
        // - but we should be aware of the fact that some
        // products already have tax in the price
        return productID == orderItem.productID
    }
}
