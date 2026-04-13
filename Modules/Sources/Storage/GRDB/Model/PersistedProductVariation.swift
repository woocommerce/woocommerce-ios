import Foundation
import GRDB

// periphery:ignore - TODO: remove ignore when populating database
public struct PersistedProductVariation: Codable {
    public let id: Int64
    public let siteID: Int64
    public let productID: Int64
    public let typeKey: String
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
                typeKey: String = "variation",
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
        self.typeKey = typeKey
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

// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductVariation: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "productVariation" }

    public static var primaryKey: [String] { [CodingKeys.siteID.stringValue, CodingKeys.id.stringValue] }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let siteID = Column(CodingKeys.siteID)
        public static let productID = Column(CodingKeys.productID)
        public static let typeKey = Column(CodingKeys.typeKey)
        public static let sku = Column(CodingKeys.sku)
        public static let globalUniqueID = Column(CodingKeys.globalUniqueID)
        public static let price = Column(CodingKeys.price)
        public static let downloadable = Column(CodingKeys.downloadable)
        public static let fullDescription = Column(CodingKeys.fullDescription)
        public static let manageStock = Column(CodingKeys.manageStock)
        public static let stockQuantity = Column(CodingKeys.stockQuantity)
        public static let stockStatusKey = Column(CodingKeys.stockStatusKey)
    }

    public static let attributes = hasMany(PersistedProductVariationAttribute.self,
                                           key: "attributes",
                                           using: ForeignKey([PersistedProductVariationAttribute.CodingKeys.siteID.stringValue,
                                                              PersistedProductVariationAttribute.CodingKeys.productVariationID.stringValue],
                                                             to: primaryKey))

    // Join table association (internal - used by 'image' through association)
    private static let productVariationImage = hasOne(PersistedProductVariationImage.self,
                                                      key: "productVariationImage",
                                                      using: ForeignKey([PersistedProductVariationImage.CodingKeys.siteID.stringValue,
                                                                         PersistedProductVariationImage.CodingKeys.productVariationID.stringValue],
                                                                        to: primaryKey))

    // Through association to access actual image via join table (use this to fetch image)
    public static let image = hasOne(PersistedImage.self,
                                     through: productVariationImage,
                                     using: PersistedProductVariationImage.image,
                                     key: "image")

    // Relationship to parent product
    public static let parentProduct = belongsTo(PersistedProduct.self,
                                                using: ForeignKey([Columns.siteID, Columns.productID],
                                                                 to: [PersistedProduct.Columns.siteID, PersistedProduct.Columns.id]))
}

// MARK: - Point of Sale Requests
public extension PersistedProductVariation {
    /// Returns a request for non-downloadable variations of a parent product, ordered by ID
    static func posVariationsRequest(siteID: Int64, parentProductID: Int64) -> QueryInterfaceRequest<PersistedProductVariation> {
        return baseQuery(siteID: siteID)
            .filter(Columns.productID == parentProductID)
            .order(Columns.id)
    }

    /// Returns a request for all non-downloadable variations for a site
    static func posAllVariationsRequest(siteID: Int64) -> QueryInterfaceRequest<PersistedProductVariation> {
        return baseQuery(siteID: siteID)
    }

    /// Base query for POS-supported variations (non-downloadable) for a given site
    private static func baseQuery(siteID: Int64) -> QueryInterfaceRequest<PersistedProductVariation> {
        return PersistedProductVariation
            .filter(Columns.siteID == siteID)
            .filter(Columns.typeKey == "variation")
            .filter(Columns.downloadable == false)
    }

    /// Searches for a POS-supported variation by global unique ID
    /// - Parameters:
    ///   - siteID: The site ID
    ///   - globalUniqueID: The global unique ID (barcode) to search for
    /// - Returns: A query request that matches variations with the given global unique ID
    static func posVariationByGlobalUniqueID(siteID: Int64, globalUniqueID: String) -> QueryInterfaceRequest<PersistedProductVariation> {
        return PersistedProductVariation
            .filter(Columns.siteID == siteID)
            .filter(Columns.globalUniqueID == globalUniqueID)
    }
}

extension PersistedProductVariation {
    enum CodingKeys: String, CodingKey {
        case id
        case siteID
        case productID
        case typeKey
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
