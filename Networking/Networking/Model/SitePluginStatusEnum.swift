import Foundation

/// Represents all of the possible Site Plugin Statuses in enum form
///
public enum SitePluginStatusEnum: Decodable, Hashable, GeneratedFakeable {
    case active
    case networkActive
    case inactive
    case unknown
}

/// RawRepresentable Conformance
///
extension SitePluginStatusEnum: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.active:
            self = .active
        case Keys.networkActive:
            self = .networkActive
        case Keys.inactive:
            self = .inactive
        default:
            self = .unknown
        }
    }

    /// Returns the current Enum Case's raw value
    ///
    public var rawValue: String {
        switch self {
        case .active:        return Keys.active
        case .networkActive: return Keys.networkActive
        case .inactive:      return Keys.inactive
        case .unknown:       return Keys.unknown
        }
    }
}

/// Enum containing all possible plugin status keys
/// Based on wp-includes/rest-api/endpoints/class-wp-rest-plugins-controller.php
/// Note that unknown is NOT a core WP plugin REST API concept, but
/// is included for graceful degradation if an unrecognized plugin state
/// were to arrive in the GET plugins API response
///
private enum Keys {
    static let active        = "active"
    static let networkActive = "network-active"
    static let inactive      = "inactive"
    static let unknown       = "unknown"
}
