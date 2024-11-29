import Foundation
import typealias Yosemite.POSOrderableItem
import enum Yosemite.ProductType
import struct Yosemite.OrderSyncProductInput
import protocol Yosemite.OrderSyncProductTypeProtocol
import struct Yosemite.ProductBundleItem
import struct Yosemite.OrderItem

final class MockPOSItem: POSOrderableItem, Equatable {
    var name: String
    var id: UUID
    var formattedPrice: String
    var productImageSource: String?

    init(name: String,
         id: UUID = UUID(),
         formattedPrice: String,
         productImageSource: String? = nil,
         orderItemsToMatch: [OrderItem] = []) {
        self.name = name
        self.id = id
        self.formattedPrice = formattedPrice
        self.productImageSource = productImageSource
        self.orderItemsToMatch = orderItemsToMatch
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
    func matches(orderItem: OrderItem) -> Bool {
        guard orderItemsToMatch.contains(orderItem) == true else {
            return false
        }
        return true
    }

    static func == (lhs: MockPOSItem, rhs: MockPOSItem) -> Bool {
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
