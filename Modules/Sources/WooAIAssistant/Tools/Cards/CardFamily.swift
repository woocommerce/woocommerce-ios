import Foundation

public enum CardFamily: String, Sendable, Decodable, Equatable, CaseIterable {
    case order
    case product
    case productVariation = "product_variation"
    case customer
    case analyticsStats = "analytics_stats"
}
