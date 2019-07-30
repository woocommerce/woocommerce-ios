import Foundation

public struct OrderCount: Decodable {
    public let items: [OrderCountItem]

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
