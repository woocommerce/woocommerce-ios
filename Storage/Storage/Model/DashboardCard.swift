import Codegen
import Foundation

/// Represents a card on the Dashboard screen.
public struct DashboardCard: Codable, Hashable, Equatable, GeneratedCopiable {
    /// The type of dashboard card.
    public let type: CardType

    /// Whether the card is enabled in the Analytics Hub.
    public var enabled: Bool

    public init(type: CardType, enabled: Bool) {
        self.type = type
        self.enabled = enabled
    }

    /// Types of cards to display on the Dashboard screen.
    /// The order of the cases in this enum defines the default order.
    public enum CardType: String, Codable, CaseIterable {
        case onboarding
        case performance
        case topPerformers
        case blaze
    }
}
