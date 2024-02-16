import Foundation

/// Represents an analytics report card in the Analytics Hub
public struct AnalyticsCard: Codable, Hashable, Equatable, Comparable {
    /// The type of analytics report card.
    public let type: CardType

    /// Whether the card is enabled in the Analytics Hub.
    public let enabled: Bool

    /// The card's order in a sorted list of cards in the Analytics Hub.
    public let sortOrder: Int

    public init(type: CardType, enabled: Bool, sortOrder: Int) {
        self.type = type
        self.enabled = enabled
        self.sortOrder = sortOrder
    }

    /// Types of report cards to display in the Analytics Hub.
    public enum CardType: Codable, CaseIterable {
        case revenue
        case orders
        case products
        case sessions
    }

    /// The default set of cards for the Analytics Hub.
    /// Provides all card types enabled in their default order.
    public static let defaultCards: Set<AnalyticsCard> = {
        let allCards = CardType.allCases.map { type in
            AnalyticsCard(type: type, enabled: true, sortOrder: CardType.allCases.firstIndex(of: type) ?? 0)
        }
        return Set(allCards)
    }()
}

// MARK: - Comparable conformance
extension AnalyticsCard {
    public static func < (lhs: AnalyticsCard, rhs: AnalyticsCard) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}
