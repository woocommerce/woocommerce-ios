import Codegen
import Foundation

/// Represents a card on the Dashboard screen.
public struct DashboardCard: Codable, Hashable, Equatable, GeneratedCopiable {
    /// The type of dashboard card.
    public let type: CardType

    /// The card's availability state for the site.
    /// To be set externally based on each card's availability check.
    public var isAvailable: Bool

    /// User-changeable setting in the Customize screen, whether to enable or disable an available card.
    /// An available card will become invisible on the Dashboard, but stay visible on Customize, if `enabled` is set to false.
    public var enabled: Bool

    /// Whether the card is shown on the Dashboard screen.
    var isVisible: Bool {
        if status == .hide || status == .unavailable {
            return false
        } else {
            return enabled
        }
    }

    /// Determines how a card is shown in the Customize screen
    public var status: CustomizeState

    public init(type: CardType, isAvailable: Bool, enabled: Bool, status: CustomizeState) {
        self.type = type
        self.isAvailable = isAvailable
        self.enabled = enabled
        self.status = status
    }

    /// Types of cards to display on the Dashboard screen.
    /// The order of the cases in this enum defines the default order.
    public enum CardType: String, Codable, CaseIterable {
        case onboarding
        case performance
        case topPerformers
        case blaze
    }

    /// Determines how card is shown in the Customize screen
    public enum CustomizeState: String, Codable {
        case show           // Card is available and can be enabled/disabled/ordered.
        case unavailable    // Card shown as "Unavailable" and can't be enabled/disabled/ordered.
        case hide           // Card is not available and not shown on the screen screen.
    }
}
