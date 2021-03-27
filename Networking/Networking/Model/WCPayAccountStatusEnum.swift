import Foundation

/// Represents all of the possible Site Plugin Statuses in enum form
///
public enum WCPayAccountStatusEnum: Decodable, Hashable, GeneratedFakeable {
    case noAccount
    case complete
    case restricted
    case restrictedSoon
    case rejected
}

/// RawRepresentable Conformance
///
extension WCPayAccountStatusEnum: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.complete:
            self = .complete
        case Keys.restricted:
            self = .restricted
        case Keys.restrictedSoon:
            self = .restrictedSoon
        case Keys.rejected:
            self = .rejected
        default:
            self = .noAccount
        }
    }

    /// Returns the current Enum Case's raw value
    ///
    public var rawValue: String {
        switch self {
        case .complete:       return Keys.complete
        case .restricted:     return Keys.restricted
        case .restrictedSoon: return Keys.restrictedSoon
        case .rejected:       return Keys.rejected
        case .noAccount:      return Keys.noAccount
        }
    }
}

/// Enum containing all possible account status keys
///
private enum Keys {
    static let complete       = "complete"
    static let restricted     = "restricted"
    static let restrictedSoon = "restricted_soon"
    static let rejected       = "rejected"
    static let noAccount      = ""
}
