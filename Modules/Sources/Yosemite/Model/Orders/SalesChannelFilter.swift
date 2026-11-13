import Foundation

/// Used to filter orders by sales channel
///
public enum SalesChannelFilter: String, Codable, Hashable, Sendable {
    case pointOfSale
    case webCheckout
    case wpAdmin
    case any
}
