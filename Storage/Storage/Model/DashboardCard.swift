import Codegen
import Foundation

/// Represents a card on the Dashboard screen.
public struct DashboardCard: Codable, Hashable, Equatable, GeneratedCopiable, Sendable {
    /// The type of dashboard card.
    public let type: CardType

    /// The card's availability state for the site.
    /// To be set externally based on each card's availability check.
    public let availability: AvailabilityState

    /// User-changeable setting in the Customize screen, whether to enable or disable an available card.
    /// An available card will become invisible on the Dashboard, but stay visible on Customize, if `enabled` is set to false.
    public let enabled: Bool

    public init(type: CardType, availability: AvailabilityState, enabled: Bool) {
        self.type = type
        self.availability = availability
        self.enabled = enabled
    }

    /// Types of cards to display on the Dashboard screen.
    public enum CardType: String, Codable, CaseIterable, Sendable {
        case onboarding
        case performance
        case topPerformers
        case blaze
        case inbox
        case stock
        case reviews
        case lastOrders
        case coupons
        case googleAds
    }

    /// Card's availability state that determines whether it can be displayed and used.
    /// Affects how it's shown (or not shown) in Dashboard and Customize.
    public enum AvailabilityState: String, Codable, Sendable {
        case show           // Shown in Dashboard and Customize
        case unavailable    // Shown in Dashboard and Customize (as "Unavailable")
        case hide           // Not shown in Dashboard and Customize
    }
}
