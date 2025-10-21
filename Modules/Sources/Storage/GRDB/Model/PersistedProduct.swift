import Foundation
import GRDB

// periphery:ignore - TODO: remove ignore when populating database
public struct PersistedProduct: Codable {
    public let id: Int64
    public let siteID: Int64
    public let name: String
    public let productTypeKey: String
    public let fullDescription: String?
    public let shortDescription: String?
    public let sku: String?
    public let globalUniqueID: String?
    public let price: String
    public let downloadable: Bool
    public let parentID: Int64
    public let manageStock: Bool
    public let stockQuantity: Decimal?
    public let stockStatusKey: String

    public init(id: Int64,
                siteID: Int64,
                name: String,
                productTypeKey: String,
                fullDescription: String?,
                shortDescription: String?,
                sku: String?,
                globalUniqueID: String?,
                price: String,
                downloadable: Bool,
                parentID: Int64,
                manageStock: Bool,
                stockQuantity: Decimal?,
                stockStatusKey: String) {
        self.id = id
        self.siteID = siteID
        self.name = name
        self.productTypeKey = productTypeKey
        self.fullDescription = fullDescription
        self.shortDescription = shortDescription
        self.sku = sku
        self.globalUniqueID = globalUniqueID
        self.price = price
        self.downloadable = downloadable
        self.parentID = parentID
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
    }
}

// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProduct: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "product" }

    public static var primaryKey: [String] { [CodingKeys.siteID.stringValue, CodingKeys.id.stringValue] }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let siteID = Column(CodingKeys.siteID)
        public static let name = Column(CodingKeys.name)
        public static let productTypeKey = Column(CodingKeys.productTypeKey)
        public static let fullDescription = Column(CodingKeys.fullDescription)
        public static let shortDescription = Column(CodingKeys.shortDescription)
        public static let sku = Column(CodingKeys.sku)
        public static let globalUniqueID = Column(CodingKeys.globalUniqueID)
        public static let price = Column(CodingKeys.price)
        public static let downloadable = Column(CodingKeys.downloadable)
        public static let parentID = Column(CodingKeys.parentID)
        public static let manageStock = Column(CodingKeys.manageStock)
        public static let stockQuantity = Column(CodingKeys.stockQuantity)
        public static let stockStatusKey = Column(CodingKeys.stockStatusKey)
    }

    // Join table association (internal - used by 'images' through association)
    private static let productImages = hasMany(PersistedProductImage.self,
                                               using: ForeignKey([PersistedProductImage.CodingKeys.siteID.stringValue,
                                                                  PersistedProductImage.CodingKeys.productID.stringValue],
                                                                 to: primaryKey))

    // Through association to access actual images via join table (use this to fetch images)
    public static let images = hasMany(PersistedImage.self,
                                       through: productImages,
                                       using: PersistedProductImage.image)

    public static let attributes = hasMany(PersistedProductAttribute.self,
                                           key: "attributes",
                                           using: ForeignKey([PersistedProductAttribute.CodingKeys.siteID.stringValue,
                                                              PersistedProductAttribute.CodingKeys.productID.stringValue],
                                                             to: primaryKey))
}

// MARK: - Point of Sale Requests
public extension PersistedProduct {
    /// Returns a request for POS-supported products (simple and variable, non-downloadable) for a given site, ordered by name
    static func posProductsRequest(siteID: Int64) -> QueryInterfaceRequest<PersistedProduct> {
        return PersistedProduct
            .filter(Columns.siteID == siteID)
            .filter([ProductType.simple.rawValue, ProductType.variable.rawValue].contains(Columns.productTypeKey))
            .filter(Columns.downloadable == false)
            .order(Columns.name.collating(.localizedCaseInsensitiveCompare))
    }

    /// Searches for a POS-supported product by global unique ID
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - globalUniqueID: The global unique ID (barcode) to search for
    /// - Returns: A query request that matches products with the given global unique ID
    static func posProductByGlobalUniqueID(siteID: Int64, globalUniqueID: String) -> QueryInterfaceRequest<PersistedProduct> {
        return PersistedProduct
            .posProductsRequest(siteID: siteID)
            .filter(Columns.globalUniqueID == globalUniqueID)
    }
}

// periphery:ignore - TODO: remove ignore when populating database
private extension PersistedProduct {
    enum CodingKeys: String, CodingKey {
        case id
        case siteID
        case name
        case productTypeKey
        case fullDescription
        case shortDescription
        case sku
        case globalUniqueID
        case price
        case downloadable
        case parentID
        case manageStock
        case stockQuantity
        case stockStatusKey
    }

    enum ProductType: String {
        case simple
        case variable
    }
}
