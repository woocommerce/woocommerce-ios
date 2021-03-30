import Foundation

/// Represents all of the possible Site Plugin Statuses in enum form
///
public enum WCPayAccountStatusEnum: Decodable, Hashable, GeneratedFakeable {
    /// Complete: This is the normal state for a fully functioning WCPay account. The merchant should be able to collect
    /// card present payments.
    case complete

    /// restricted: This state occurs when there is required business information missing from the account.
    /// If hasOverdueRequirements is also true, then the deadline for providing that information HAS PASSED.
    /// The merchant will probably NOT be able to collect card present payments.
    /// Otherwise, if hasPendingRequirements is true, then the deadline for providing that information has not yet passed.
    /// The deadline is available in currentDeadline. The merchant will probably be able to collect card present payments
    /// until the deadline.
    /// Otherwise, if neither hasOverdueRequirements nor hasPendingRequirements is true, then the account is under
    /// review by Stripe. The merchant will probably not be able to collect card present payments.
    case restricted

    /// rejectedFraud: This state occurs when our payment processor rejects the merchant account due to suspected fraudulent
    /// activity. The merchant will NOT be able to collect card present payments.
    case rejectedFraud

    /// rejectedTermsOfService: This state occurs when our payment processor rejects the merchant account due to terms of
    /// service violation(s). The merchant will NOT be able to collect card present payments.
    case rejectedTermsOfService

    /// rejectedListed: This state occurs when our payment processor rejects the merchant account due to sanctions/being
    /// on a watch list. The merchant will NOT be able to collect card present payments.
    case rejectedListed

    /// rejectedListed: This state occurs when our payment processor rejects the merchant account due to any other reason.
    /// The merchant will NOT be able to collect card present payments.
    case rejectedOther

    /// noAccount: This state occurs when the merchant hasn't started on-boarding yet. The merchant will NOT be able to
    /// collect card present payments.
    case noAccount

    /// unknown: This state occurs when the self-hosted site responded in a way we don't recognize.
    case unknown
}

/// RawRepresentable Conformance
///
extension WCPayAccountStatusEnum: RawRepresentable {

    /// Designated Initializer. Takes the string in the response and returns the enum
    /// assocated with that value. Empty strings return .noAccount
    /// If not recognized, returns .unknown
    ///
    public init(rawValue: String) {
        switch rawValue {
        case Keys.complete:
            self = .complete
        case Keys.restricted:
            self = .restricted
        case Keys.rejectedFraud:
            self = .rejectedFraud
        case Keys.rejectedTermsOfService:
            self = .rejectedTermsOfService
        case Keys.rejectedListed:
            self = .rejectedListed
        case Keys.rejectedOther:
            self = .rejectedOther
        case Keys.noAccount:
            self = .noAccount
        default:
            self = .unknown
        }
    }

    /// Returns the current Enum Case's raw value
    ///
    public var rawValue: String {
        switch self {
        case .complete:               return Keys.complete
        case .restricted:             return Keys.restricted
        case .rejectedFraud:          return Keys.rejectedFraud
        case .rejectedTermsOfService: return Keys.rejectedTermsOfService
        case .rejectedListed:         return Keys.rejectedListed
        case .rejectedOther:          return Keys.rejectedOther
        case .noAccount:              return Keys.noAccount
        case .unknown:                return Keys.unknown
        }
    }
}

/// Enum containing all possible account status keys
///
private enum Keys {
    static let complete               = "complete"
    static let restricted             = "restricted"
    static let rejectedFraud          = "rejected.fraud"
    static let rejectedTermsOfService = "rejected.terms_of_service"
    static let rejectedListed         = "rejected.listed"
    static let rejectedOther          = "rejected.other"
    static let noAccount              = "NOACCOUNT" /// The status field will be not present in the API response when no account has been set up.
    static let unknown                = "UNKNOWN" /// This value does NOT appear in the API response. It is a default case for unrecognized responses.
}
