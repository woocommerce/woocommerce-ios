import Foundation


/// Represents a single top earner stat for a specific period.
///
public struct TopEarnerStatsItem: Decodable {

    /// Product ID
    ///
    public let productID: Int

    /// Product name
    ///
    public let pruductName: String

    /// Quantity sold
    ///
    public let quantity: Int

    /// Average price of item
    ///
    public let price: Double

    /// Total revenue from product
    ///
    public let total: Double

    /// Currency
    ///
    public let currency: String

    /// Image URL for product
    ///
    public let imageUrl: String?


    /// Designated Initializer.
    ///
    public init(productID: Int, pruductName: String, quantity: Int, price: Double, total: Double, currency: String, imageUrl: String?) {
        self.productID = productID
        self.pruductName = pruductName
        self.quantity = quantity
        self.price = price
        self.total = total
        self.currency = currency
        self.imageUrl = imageUrl
    }
}


/// Defines all of the TopEarnerStatsItem CodingKeys.
///
private extension TopEarnerStatsItem {
    enum CodingKeys: String, CodingKey {
        case productID = "ID"
        case pruductName = "name"
        case total = "total"
        case quantity = "quantity"
        case price = "price"
        case imageUrl = "image"
        case currency = "currency"
    }
}


// MARK: - Comparable Conformance
//
extension TopEarnerStatsItem: Comparable {
    public static func == (lhs: TopEarnerStatsItem, rhs: TopEarnerStatsItem) -> Bool {
        return lhs.productID == rhs.productID &&
            lhs.pruductName == rhs.pruductName &&
            lhs.quantity == rhs.quantity &&
            lhs.price == rhs.price &&
            lhs.total == rhs.total &&
            lhs.currency == rhs.currency &&
            lhs.imageUrl == rhs.imageUrl
    }

    public static func < (lhs: TopEarnerStatsItem, rhs: TopEarnerStatsItem) -> Bool {
        return lhs.quantity < rhs.quantity ||
            (lhs.quantity == rhs.quantity && lhs.pruductName < rhs.pruductName)
    }
}
