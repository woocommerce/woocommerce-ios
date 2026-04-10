import Foundation
import Codegen

/// Represents an analytics report card in the Analytics Hub
public struct AnalyticsCard: Codable, Hashable, Equatable, GeneratedCopiable {
    /// The type of analytics report card.
    public let type: CardType

    /// Whether the card is enabled in the Analytics Hub.
    public var enabled: Bool

    public init(type: CardType, enabled: Bool) {
        self.type = type
        self.enabled = enabled
    }

    /// Types of report cards to display in the Analytics Hub.
    /// The order of the cases in this enum defines the default order of cards in the Analytics Hub.
    public enum CardType: String, Codable, CaseIterable {
        case revenue
        case orders
        case products
        case sessions
        case bundles
        case giftCards
        case googleCampaigns
    }
}
