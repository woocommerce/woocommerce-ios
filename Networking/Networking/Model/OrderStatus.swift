import Foundation


/// Represents an OrderStatus Entity.
///
public struct OrderStatus: Decodable {
    public let name: String?
    public let siteID: Int64
    public let slug: String
    public let total: Int

    public var status: OrderStatusEnum {
        return OrderStatusEnum(rawValue: slug)
    }

    /// OrderStatus struct initializer.
    ///
    public init(name: String?, siteID: Int64, slug: String, total: Int) {
        self.name = name
        self.siteID = siteID
        self.slug = slug
        self.total = total
    }

    /// The public initializer for OrderStatus.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw OrderStatusError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .name)
        let slug = try container.decode(String.self, forKey: .slug)
        let total = try container.decode(Int.self, forKey: .total)

        self.init(name: name, siteID: siteID, slug: slug, total: total) // initialize the struct
    }
}


/// Defines all of the OrderStatus's CodingKeys.
///
private extension OrderStatus {

    enum CodingKeys: String, CodingKey {
        case name
        case slug
        case total
    }
}


// MARK: - Comparable Conformance
//
extension OrderStatus: Comparable {
    public static func == (lhs: OrderStatus, rhs: OrderStatus) -> Bool {
        return lhs.name == rhs.name &&
            lhs.slug == rhs.slug &&
            lhs.total == rhs.total
    }

    public static func < (lhs: OrderStatus, rhs: OrderStatus) -> Bool {
        return lhs.total < rhs.total ||
            (lhs.total == rhs.total && lhs.slug < rhs.slug)
    }
}


// MARK: - Decoding Errors
//
enum OrderStatusError: Error {
    case missingSiteID
}
