import Foundation
import typealias Yosemite.POSOrderableItem
import enum Yosemite.ProductType
import struct Yosemite.OrderSyncProductInput
import protocol Yosemite.OrderSyncProductTypeProtocol
import struct Yosemite.ProductBundleItem
import struct Yosemite.OrderItem

struct MockPOSItem: POSOrderableItem {
    var name: String
    var id: UUID = UUID()
    var formattedPrice: String
    var productImageSource: String? = nil

    func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput {
        OrderSyncProductInput(
            id: 1,
            product: .product(MockOrderSyncProductType(price: "", productID: 1, productType: .simple, bundledItems: [])),
            quantity: quantity,
            discount: .zero,
            baseSubtotal: .zero,
            bundleConfiguration: [])
    }

    func matches(orderItem: OrderItem) -> Bool {
        return false
    }
}

struct MockOrderSyncProductType: OrderSyncProductTypeProtocol {
    var price: String
    var productID: Int64
    var productType: ProductType
    var bundledItems: [ProductBundleItem]
}
