import Foundation
import Networking

public struct POSVariation: OrderSyncProductVariationTypeProtocol, Equatable, Hashable, Identifiable {
    // Identifiable & POSOrderableItem
    public let id: POSItemIdentifier

    // POSOrderableItem
    public let name: String
    public let formattedPrice: String
    public var productImageSource: String?

    // OrderSyncProductVariationTypeProtocol
    public let productID: Int64
    public let productVariationID: Int64
    public let price: String

    // Variation specific
    public let parentProductName: String

    // Stock
    public let manageStock: Bool
    public let stockQuantity: Decimal?
    public let stockStatusKey: String
    public let pointOfSaleStockQuantity: Decimal?
    public let parentManageStock: Bool
    public let parentStockQuantity: Decimal?
    public let parentStockStatusKey: String
    public let parentPointOfSaleStockQuantity: Decimal?

    public var productStockStatus: ProductStockStatus {
        return ProductStockStatus(rawValue: stockStatusKey)
    }
    public var parentProductStockStatus: ProductStockStatus {
        return ProductStockStatus(rawValue: parentStockStatusKey)
    }

    public init(id: POSItemIdentifier,
                name: String,
                formattedPrice: String,
                price: String,
                productImageSource: String? = nil,
                productID: Int64,
                variationID: Int64,
                parentProductName: String,
                manageStock: Bool = false,
                stockQuantity: Decimal? = nil,
                stockStatusKey: String = "",
                pointOfSaleStockQuantity: Decimal? = nil,
                parentManageStock: Bool = false,
                parentStockQuantity: Decimal? = nil,
                parentStockStatusKey: String = "",
                parentPointOfSaleStockQuantity: Decimal? = nil) {
        self.id = id
        self.name = name
        self.formattedPrice = formattedPrice
        self.price = price
        self.productImageSource = productImageSource
        self.productID = productID
        self.productVariationID = variationID
        self.parentProductName = parentProductName
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
        self.pointOfSaleStockQuantity = pointOfSaleStockQuantity
        self.parentManageStock = parentManageStock
        self.parentStockQuantity = parentStockQuantity
        self.parentStockStatusKey = parentStockStatusKey
        self.parentPointOfSaleStockQuantity = parentPointOfSaleStockQuantity
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
