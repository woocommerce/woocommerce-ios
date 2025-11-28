import Foundation
@testable import Yosemite

final class MockPOSOrderableItem: POSOrderableItem, Equatable {
    var name: String
    var id: POSItemIdentifier
    var formattedPrice: String
    var productImageSource: String?

    init(name: String,
         id: POSItemIdentifier = POSItemIdentifier(underlyingType: .product, itemID: 1),
         formattedPrice: String,
         productImageSource: String? = nil,
         orderItemsToMatch: [OrderItem] = [],
         matcher: ((OrderItem) -> Bool)? = nil) {
        self.name = name
        self.id = id
        self.formattedPrice = formattedPrice
        self.productImageSource = productImageSource
        self.orderItemsToMatch = orderItemsToMatch
        self.matcher = matcher
    }

    func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput {
        OrderSyncProductInput(
            id: 1,
            product: .product(MockOrderSyncProductType(price: "", productID: 1, productType: .simple, bundledItems: [])),
            quantity: quantity,
            discount: .zero,
            baseSubtotal: .zero,
            bundleConfiguration: [])
    }

    var orderItemsToMatch: [OrderItem]
    var matcher: ((OrderItem) -> Bool)?
    func matches(orderItem: OrderItem) -> Bool {
        if let matcher {
            return matcher(orderItem)
        }

        guard orderItemsToMatch.contains(orderItem) == true else {
            return false
        }
        return true
    }

    static func == (lhs: MockPOSOrderableItem, rhs: MockPOSOrderableItem) -> Bool {
        return lhs.name == rhs.name &&
        lhs.id == rhs.id &&
        lhs.formattedPrice == rhs.formattedPrice &&
        lhs.productImageSource == rhs.productImageSource
    }
}

struct MockOrderSyncProductType: OrderSyncProductTypeProtocol {
    var price: String
    var productID: Int64
    var productType: ProductType
    var bundledItems: [ProductBundleItem]
}
