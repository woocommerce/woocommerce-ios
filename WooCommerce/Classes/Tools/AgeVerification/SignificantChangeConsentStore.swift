import Foundation

enum SignificantChangeIdentifier: Hashable {
    /// Automatically detected App Store age rating change.
    case ageRatingChange(ratingCode: Int)
    /// Developer-declared significant change not tied to an age rating (e.g. a feature
    /// or policy change we decide requires renewed parental consent).
    case manual(id: String)

    /// Persisted discriminator of each case. The raw values are part of the on-disk format
    /// of `cacheKey`: renaming one orphans every status stored under the old name.
    private enum Kind: String {
        case ageRatingChange
        case manual
    }

    private static let cacheKeySeparator: Character = "."

    /// Stable key the consent status is persisted under: `<kind>.<payload>`.
    var cacheKey: String {
        switch self {
        case let .ageRatingChange(ratingCode):
            return Self.cacheKey(kind: .ageRatingChange, payload: String(ratingCode))
        case let .manual(id):
            return Self.cacheKey(kind: .manual, payload: id)
        }
    }

    init?(cacheKey: String) {
        guard let separatorIndex = cacheKey.firstIndex(of: Self.cacheKeySeparator),
              let kind = Kind(rawValue: String(cacheKey[..<separatorIndex])) else {
            return nil
        }
        // Only the first separator splits kind from payload: a manual id may itself contain dots.
        let payload = String(cacheKey[cacheKey.index(after: separatorIndex)...])
        switch kind {
        case .ageRatingChange:
            guard let ratingCode = Int(payload) else { return nil }
            self = .ageRatingChange(ratingCode: ratingCode)
        case .manual:
            self = .manual(id: payload)
        }
    }

    private static func cacheKey(kind: Kind, payload: String) -> String {
        kind.rawValue + String(cacheKeySeparator) + payload
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

    /// Removes every persisted consent status and the pending request. Debug/testing helper.
    static func resetAll(in defaults: UserDefaults = .standard) {
        defaults.dictionaryRepresentation().keys
            .filter { $0.hasPrefix(Key.prefix) }
            .forEach { defaults.removeObject(forKey: $0) }
        defaults.removeObject(forKey: Key.pendingRequest)
    }
}
