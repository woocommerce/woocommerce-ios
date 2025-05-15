import WooFoundation
import Codegen
import Networking

public struct POSSimpleProduct: POSOrderableItem, OrderSyncProductTypeProtocol {
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

    // Stock
    public let manageStock: Bool
    public let stockQuantity: Decimal? // Core API reports Int or null; some extensions allow decimal values as well
    public let stockStatusKey: String // instock, outofstock, backorder

    public init(id: UUID,
                name: String,
                formattedPrice: String,
                productImageSource: String? = nil,
                productID: Int64,
                price: String,
                productType: ProductType = .simple,
                bundledItems: [ProductBundleItem] = [],
                manageStock: Bool, stockQuantity: Decimal?, stockStatusKey: String) {
        self.id = id
        self.name = name
        self.formattedPrice = formattedPrice
        self.productImageSource = productImageSource
        self.productID = productID
        self.price = price
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
    }
}

extension POSSimpleProduct {
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
    
//    public mutating func updateQuantity() {
//        if let stockQuantity = stockQuantity {
//            stockQuantity -= 1
//        }
//    }
}

extension POSSimpleProduct: GeneratedFakeable, GeneratedCopiable, Hashable, Equatable {}
