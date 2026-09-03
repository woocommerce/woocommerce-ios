import Foundation

enum SignificantChangeIdentifier: Hashable {
    /// Automatically detected App Store age rating change.
    case ageRatingChange(ratingCode: Int)
    /// Developer-declared significant change not tied to an age rating (e.g. a feature
    /// or policy change we decide requires renewed parental consent).
    case manual(id: String)

    var cacheKey: String {
        switch self {
        case let .ageRatingChange(ratingCode):
            return "ageRatingChange.\(ratingCode)"
        case let .manual(id):
            return "manual.\(id)"
        }
    }

    init?(cacheKey: String) {
        if cacheKey.hasPrefix("ageRatingChange."),
           let ratingCode = Int(cacheKey.dropFirst("ageRatingChange.".count)) {
            self = .ageRatingChange(ratingCode: ratingCode)
        } else if cacheKey.hasPrefix("manual.") {
            self = .manual(id: String(cacheKey.dropFirst("manual.".count)))
        } else {
            return nil
        }
    }
}

enum SignificantChangeConsentStatus: String {
    case granted
    case denied
    /// The question was handed to the system but the parent/guardian hasn't answered yet.
    case pending
}

/// A consent question that was sent and is awaiting the parent/guardian answer.
/// The answer can arrive at any time — including after an app relaunch — through
/// `SignificantChangeConsentProviding.responses()`, matched by `questionID`.
struct PendingConsentRequest: Equatable {
    let questionID: UUID
    let identifier: SignificantChangeIdentifier
}

protocol SignificantChangeConsentStoring {
    func status(for identifier: SignificantChangeIdentifier) -> SignificantChangeConsentStatus?
    func setStatus(_ status: SignificantChangeConsentStatus, for identifier: SignificantChangeIdentifier)
    /// Removes the stored status so the question can be asked again (recovery from a denial).
    func clearStatus(for identifier: SignificantChangeIdentifier)

    /// The single outstanding question, if any. Only one significant-change question is in flight at a time.
    var pendingRequest: PendingConsentRequest? { get }
    func setPendingRequest(_ request: PendingConsentRequest)
    func clearPendingRequest()
}

final class UserDefaultsSignificantChangeConsentStore: SignificantChangeConsentStoring {
    private enum Key {
        static let prefix = "com.woocommerce.ios.significantChangeConsent.status."
        static let pendingRequest = "com.woocommerce.ios.significantChangeConsent.pendingRequest"
        static let pendingQuestionID = "questionID"
        static let pendingIdentifier = "identifier"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func status(for identifier: SignificantChangeIdentifier) -> SignificantChangeConsentStatus? {
        let key = Key.prefix + identifier.cacheKey
        guard let rawValue = defaults.string(forKey: key) else { return nil }
        return SignificantChangeConsentStatus(rawValue: rawValue)
    }

    func setStatus(_ status: SignificantChangeConsentStatus, for identifier: SignificantChangeIdentifier) {
        let key = Key.prefix + identifier.cacheKey
        defaults.set(status.rawValue, forKey: key)
    }

    func clearStatus(for identifier: SignificantChangeIdentifier) {
        defaults.removeObject(forKey: Key.prefix + identifier.cacheKey)
    }

    var pendingRequest: PendingConsentRequest? {
        guard let dictionary = defaults.dictionary(forKey: Key.pendingRequest),
              let questionIDString = dictionary[Key.pendingQuestionID] as? String,
              let questionID = UUID(uuidString: questionIDString),
              let identifierCacheKey = dictionary[Key.pendingIdentifier] as? String,
              let identifier = SignificantChangeIdentifier(cacheKey: identifierCacheKey) else {
            return nil
        }
        return PendingConsentRequest(questionID: questionID, identifier: identifier)
    }

    func setPendingRequest(_ request: PendingConsentRequest) {
        defaults.set(
            [
                Key.pendingQuestionID: request.questionID.uuidString,
                Key.pendingIdentifier: request.identifier.cacheKey
            ],
            forKey: Key.pendingRequest
        )
    }

    func clearPendingRequest() {
        defaults.removeObject(forKey: Key.pendingRequest)
    }
}
