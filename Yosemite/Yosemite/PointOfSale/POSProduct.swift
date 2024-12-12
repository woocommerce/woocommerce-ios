import WooFoundation

public struct POSProduct: POSOrderableItem, OrderSyncProductTypeProtocol, Equatable, Hashable, Identifiable {
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

extension POSProduct {
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

public protocol POSParentItem: POSDisplayableItem & PointOfSaleParentItemProtocol {}

public protocol PointOfSaleParentItemProtocol {
//    var childrenState: ItemListState { get set }
//    var currentPage: Int { get set }
//    var hasMoreChildren: Bool { get set }
}

public struct POSVariableProductParent: POSDisplayableItem, POSParentItem, Equatable {
    public static func == (lhs: POSVariableProductParent, rhs: POSVariableProductParent) -> Bool {
        return lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.formattedPrice == rhs.formattedPrice &&
        lhs.productImageSource == rhs.productImageSource
    }

    // POSDisplayableItem
    public let id: UUID
    public let name: String
    public let formattedPrice: String
    public let productImageSource: String?

    // POSParentItem
//    public var childrenState: ItemListState
//    public var currentPage: Int
//    public var hasMoreChildren: Bool

    // VariableProduct fetch requirements
    public let productID: Int64
}

//struct POSVariableProduct: POSOrderableItem, Equatable {
//    // POSDisplayableItem
//    var id: UUID
//    var parentProductID: Int64
//    var variationID: Int64
//    var name: String
//    var formattedPrice: String
//    var productImageSource: String?
//
//    // POSOrderableItem
//    func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput {
//        OrderSyncProductInput(product: .variation(POSVariationType(price: formattedPrice,
//                                                                   productVariationID: variationID,
//                                                                   productID: parentProductID)),
//                              quantity: quantity)
//    }
//
//    func matches(orderItem: OrderItem) -> Bool {
//        return variationID == orderItem.productID
////        return productID == orderItem.productID
//    }
//}
//
//struct POSVariationType: OrderSyncProductVariationTypeProtocol {
//    let price: String
//    let productVariationID: Int64
//    let productID: Int64
//
//    func isEqual(to type: any OrderSyncProductVariationTypeProtocol) -> Bool {
//        price == type.price && productVariationID == type.productVariationID && productID == type.productID
//    }
//}
