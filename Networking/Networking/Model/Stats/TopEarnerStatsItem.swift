#if os(iOS)

import Foundation
import Codegen

/// Represents a single top earner stat for a specific period.
///
public struct TopEarnerStatsItem: Decodable, Equatable, GeneratedCopiable, GeneratedFakeable {

    /// Product ID
    ///
    public let productID: Int64

    /// Product name
    ///
    public let productName: String?

    /// Quantity sold
    ///
    public let quantity: Int

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
    public init(productID: Int64, productName: String?, quantity: Int, total: Double, currency: String, imageUrl: String?) {
        self.productID = productID
        self.productName = productName ?? ""
        self.quantity = quantity
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
        case productName = "name"
        case total = "total"
        case quantity = "quantity"
        case imageUrl = "image"
        case currency = "currency"
    }
}


// MARK: - Comparable Conformance
//
extension TopEarnerStatsItem: Comparable {
    public static func < (lhs: TopEarnerStatsItem, rhs: TopEarnerStatsItem) -> Bool {
        return lhs.quantity < rhs.quantity ||
            (lhs.quantity == rhs.quantity && lhs.total < rhs.total)
    }
}

// MARK: - Identifiable Conformance
//
extension TopEarnerStatsItem: Identifiable {
    public var id: Int64 {
        productID
    }
}

#endif
