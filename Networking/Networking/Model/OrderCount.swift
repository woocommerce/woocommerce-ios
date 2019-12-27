import Foundation

/// Represents an OrderCount Entity.
/// An OrderCount contains an array of OrderCountItem.
/// Each OrderCountItem represents the number of Orders for a given status
///
public struct OrderCount {
    public let siteID: Int64
    public let items: [OrderCountItem]

    public init(siteID: Int64, items: [OrderCountItem]) {
        self.siteID = siteID
        self.items = items
    }

    /// Returns the first OrderCountItem matching a order status slug
    ///
    public subscript(slug: String) -> OrderCountItem? {
        return items.filter {
            $0.slug == slug
            }.first
    }
}
