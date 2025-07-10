import Foundation

/// Used to filter orders by sales channel
///
public enum SalesChannelFilter: String, Codable, Hashable {
    case pointOfSale = "pos-rest-api"
    case any = "any"
}
