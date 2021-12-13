import Foundation
import Codegen

/// Represents all of the possible Site Plugin Statuses in enum form
///
public enum WCPayAccountStatusEnum: Decodable, Hashable, GeneratedFakeable {
    /// This is the normal state for a fully functioning WCPay account. The merchant should be able to collect
    /// card present payments.
    case complete

    /// This state occurs when there is required business information missing from the account.
    /// If `hasOverdueRequirements` is also true, then the deadline for providing that information HAS PASSED and
    /// the merchant will probably NOT be able to collect card present payments.
    /// Otherwise, if `hasPendingRequirements` is true, then the deadline for providing that information has not yet passed.
    /// The deadline is available in `currentDeadline` and the merchant will probably be able to collect card present payments
    /// until the deadline.
    /// Otherwise, if neither `hasOverdueRequirements` nor `hasPendingRequirements` is true, then the account is under
    /// review by Stripe and the merchant will probably not be able to collect card present payments.
    case restricted

    /// This state occurs when there is required business information missing from the account but the
    /// currentDeadline hasn't passed yet (aka there are no overdueRequirements). The merchant will probably be able
    /// to collect card present payments.
    case restrictedSoon

    /// This state occurs when our payment processor rejects the merchant account due to suspected fraudulent
    /// activity. The merchant will NOT be able to collect card present payments.
    case rejectedFraud

    /// This state occurs when our payment processor rejects the merchant account due to terms of
    /// service violation(s). The merchant will NOT be able to collect card present payments.
    case rejectedTermsOfService

    /// This state occurs when our payment processor rejects the merchant account due to sanctions/being
    /// on a watch list. The merchant will NOT be able to collect card present payments.
    case rejectedListed

    /// This state occurs when our payment processor rejects the merchant account due to any other reason.
    /// The merchant will NOT be able to collect card present payments.
    case rejectedOther

    /// This state occurs when the merchant hasn't  on-boarded yet. The merchant will NOT be able to
    /// collect card present payments.
    case noAccount

    /// This state occurs when the self-hosted site responded in a way we don't recognize.
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
        case Keys.restrictedSoon:
            self = .restrictedSoon
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
        case .restrictedSoon:         return Keys.restrictedSoon
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
    /// The WCPay account is fully set up without restriction and ready for card present payments.
    static let complete               = "complete"
    /// The WCPay account is restricted - it is under review or has pending or overdue requirements.
    static let restricted             = "restricted"
    /// The WCPay account has required information missing but it's not restricted yet.
    static let restrictedSoon         = "restricted_soon"
    /// The WCPay account has been rejected due to fradulent activity.
    static let rejectedFraud          = "rejected.fraud"
    /// The WCPay account has been rejected due to violating the terms of service.
    static let rejectedTermsOfService = "rejected.terms_of_service"
    /// The WCPay account has been rejected due to a watch list or sanctions.
    static let rejectedListed         = "rejected.listed"
    /// The WCPay account has been rejected due to other reasons.
    static let rejectedOther          = "rejected.other"
    /// The WCPay account onboarding has not been completed.
    /// Note that NO fields are present in the API response in this situation. The response is simplay an empty array.
    static let noAccount              = "NOACCOUNT"
    /// An unrecognized response was returned for the account status field.
    static let unknown                = "UNKNOWN"
}
