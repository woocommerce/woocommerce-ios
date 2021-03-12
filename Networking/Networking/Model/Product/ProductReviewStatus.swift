/// Represents a ProductReviewStatus Entity.
///
public enum ProductReviewStatus: Decodable, Hashable, GeneratedFakeable {
    case approved
    case hold
    case spam
    case unspam
    case trash
    case untrash
}


/// RawRepresentable Conformance
///
extension ProductReviewStatus: RawRepresentable {

    /// Designated Initializer.
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.approved:
            self = .approved
        case Keys.hold:
            self = .hold
        case Keys.spam:
            self = .spam
        case Keys.unspam:
            self = .unspam
        case Keys.trash:
            self = .trash
        case Keys.untrash:
            self = .untrash
        default:
            self = .hold
        }
    }

    /// Returns the current Enum Case's Raw Value
    ///
    public var rawValue: String {
        switch self {
        case .approved: return Keys.approved
        case .hold:     return Keys.hold
        case .spam:     return Keys.spam
        case .unspam:   return Keys.unspam
        case .trash:    return Keys.trash
        case .untrash:  return Keys.untrash
        }
    }

    /// Returns the localized text version of the Enum
    ///
    public var description: String {
        switch self {
        case .approved:
            return NSLocalizedString("Approved", comment: "Display label for the review's approved status")
        case .hold:
            return NSLocalizedString("Pending", comment: "Display label for the review's pending status")
        case .spam:
            return NSLocalizedString("Spam", comment: "Display label for the review's spam status")
        case .unspam:
            return NSLocalizedString("Unspam", comment: "Display label for the review's unspam status")
        case .trash:
            return NSLocalizedString("Trash", comment: "Display label for the review's trash status")
        case .untrash:
            return NSLocalizedString("Untrash", comment: "Display label for the review's untrash status")
        }
    }
}


/// Enum containing the 'Known' ProductReviewStatus Keys
///
private enum Keys {
    static let approved = "approved"
    static let hold     = "hold"
    static let spam     = "spam"
    static let unspam   = "unspam"
    static let trash    = "trash"
    static let untrash  = "untrash"
}
