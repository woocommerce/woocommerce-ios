import Foundation

public struct OrderCountItem: Decodable {
    public let slug: String
    public let name: String
    public let total: Int
}


extension OrderCountItem: Comparable {
    public static func == (lhs: OrderCountItem, rhs: OrderCountItem) -> Bool {
        return lhs.slug == rhs.slug &&
            lhs.name == rhs.name &&
            lhs.total == rhs.total
    }

    public static func < (lhs: OrderCountItem, rhs: OrderCountItem) -> Bool {
        return lhs.slug == rhs.slug &&
            lhs.name == rhs.name &&
            lhs.total < rhs.total
    }
}
