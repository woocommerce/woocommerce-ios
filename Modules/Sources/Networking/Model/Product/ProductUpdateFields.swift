import Foundation

public struct ProductUpdateFields: Equatable {
    public let name: String?
    public let regularPrice: String?
    public let salePrice: String?
    public let stockQuantity: Int?
    public let status: String?

    public init(name: String? = nil,
                regularPrice: String? = nil,
                salePrice: String? = nil,
                stockQuantity: Int? = nil,
                status: String? = nil) {
        self.name = name
        self.regularPrice = regularPrice
        self.salePrice = salePrice
        self.stockQuantity = stockQuantity
        self.status = status
    }

    var parameters: [String: Any] {
        var parameters: [String: Any] = [:]
        if let name { parameters[Keys.name] = name }
        if let regularPrice { parameters[Keys.regularPrice] = regularPrice }
        if let salePrice { parameters[Keys.salePrice] = salePrice }
        if let stockQuantity {
            parameters[Keys.manageStock] = true
            parameters[Keys.stockQuantity] = stockQuantity
            parameters[Keys.stockStatus] = stockQuantity > 0 ? ProductStockStatus.inStock.rawValue : ProductStockStatus.outOfStock.rawValue
        }
        if let status { parameters[Keys.status] = status }
        return parameters
    }
}

public struct ProductVariationUpdateFields: Equatable {
    public let regularPrice: String?
    public let salePrice: String?
    public let stockQuantity: Int?
    public let stockStatus: String?
    public let sku: String?
    public let status: String?

    public init(regularPrice: String? = nil,
                salePrice: String? = nil,
                stockQuantity: Int? = nil,
                stockStatus: String? = nil,
                sku: String? = nil,
                status: String? = nil) {
        self.regularPrice = regularPrice
        self.salePrice = salePrice
        self.stockQuantity = stockQuantity
        self.stockStatus = stockStatus
        self.sku = sku
        self.status = status
    }

    var parameters: [String: Any] {
        var parameters: [String: Any] = [:]
        if let regularPrice { parameters[Keys.regularPrice] = regularPrice }
        if let salePrice { parameters[Keys.salePrice] = salePrice }
        if let stockQuantity {
            parameters[Keys.manageStock] = true
            parameters[Keys.stockQuantity] = stockQuantity
            parameters[Keys.stockStatus] = stockQuantity > 0 ? ProductStockStatus.inStock.rawValue : ProductStockStatus.outOfStock.rawValue
        }
        if let stockStatus { parameters[Keys.stockStatus] = stockStatus }
        if let sku { parameters[Keys.sku] = sku }
        if let status { parameters[Keys.status] = status }
        return parameters
    }
}

private enum Keys {
    static let name = "name"
    static let regularPrice = "regular_price"
    static let salePrice = "sale_price"
    static let manageStock = "manage_stock"
    static let stockQuantity = "stock_quantity"
    static let stockStatus = "stock_status"
    static let status = "status"
    static let sku = "sku"
}
