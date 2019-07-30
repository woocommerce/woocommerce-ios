import Foundation

public struct OrderCount: Decodable {
    public let siteID: Int
    public let items: [OrderCountItem]

    public init(siteID: Int, items: [OrderCountItem]) {
        self.siteID = siteID
        self.items = items
    }

    /// The public initializer for OrderCount.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int else {
            throw OrderCountError.missingSiteID
        }

        let container = try decoder.singleValueContainer()
        let items = try container.decode([OrderCountItem].self)

        self.init(siteID: siteID, items: items)
    }

    public subscript(slug: String) -> OrderCountItem? {
        get {
            return items.filter {
                $0.slug == slug
            }.first
        }
        set {
        }
    }
}


// MARK: - Decoding Errors
//
enum OrderCountError: Error {
    case missingSiteID
}
