import Foundation
import GRDB

public struct PersistedProductVariation: Codable {
    public let id: Int64
    public let siteID: Int64
    public let productID: Int64
    public let sku: String?
    public let globalUniqueID: String?
    public let price: String
    public let downloadable: Bool
    public let fullDescription: String?
    public let manageStock: Bool
    public let stockQuantity: Decimal?
    public let stockStatusKey: String

    public init(id: Int64,
                siteID: Int64,
                productID: Int64,
                sku: String?,
                globalUniqueID: String?,
                price: String,
                downloadable: Bool,
                fullDescription: String?,
                manageStock: Bool,
                stockQuantity: Decimal?,
                stockStatusKey: String) {
        self.id = id
        self.siteID = siteID
        self.productID = productID
        self.sku = sku
        self.globalUniqueID = globalUniqueID
        self.price = price
        self.downloadable = downloadable
        self.fullDescription = fullDescription
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
    }
}

extension PersistedProductVariation: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "productVariation" }

    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let siteID = Column(CodingKeys.siteID)
        static let productID = Column(CodingKeys.productID)
        static let sku = Column(CodingKeys.sku)
        static let globalUniqueID = Column(CodingKeys.globalUniqueID)
        static let price = Column(CodingKeys.price)
        static let downloadable = Column(CodingKeys.downloadable)
        static let fullDescription = Column(CodingKeys.fullDescription)
        static let manageStock = Column(CodingKeys.manageStock)
        static let stockQuantity = Column(CodingKeys.stockQuantity)
        static let stockStatusKey = Column(CodingKeys.stockStatusKey)
    }
}


private extension PersistedProductVariation {
    enum CodingKeys: String, CodingKey {
        case id
        case siteID
        case productID
        case sku
        case globalUniqueID
        case price
        case downloadable
        case fullDescription
        case manageStock
        case stockQuantity
        case stockStatusKey
    }
}
