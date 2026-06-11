import Foundation
import Networking

public struct POSVariableParentProduct: Equatable, Hashable, Identifiable {
    public let id: POSItemIdentifier
    public let name: String
    public let productImageSource: String?
    public let productID: Int64
    let allAttributes: [ProductAttribute]
    public let manageStock: Bool
    public let stockQuantity: Decimal?
    public let stockStatusKey: String
    public let pointOfSaleStockQuantity: Decimal?

    public var productStockStatus: ProductStockStatus {
        return ProductStockStatus(rawValue: stockStatusKey)
    }

    init(id: POSItemIdentifier,
         name: String, productImageSource: String?,
         productID: Int64,
         allAttributes: [ProductAttribute],
         manageStock: Bool = false,
         stockQuantity: Decimal? = nil,
         stockStatusKey: String = "",
         pointOfSaleStockQuantity: Decimal? = nil) {
        self.id = id
        self.name = name
        self.productImageSource = productImageSource
        self.productID = productID
        self.allAttributes = allAttributes
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
        self.pointOfSaleStockQuantity = pointOfSaleStockQuantity
    }

    #if DEBUG

    /// Initializer for SwiftUI previews.
    public init(id: POSItemIdentifier, name: String, productImageSource: String?, productID: Int64) {
        self.init(id: id, name: name, productImageSource: productImageSource, productID: productID, allAttributes: [])
    }

    #endif
}
