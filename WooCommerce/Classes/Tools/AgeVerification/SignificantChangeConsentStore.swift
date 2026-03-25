import Foundation

enum SignificantChangeIdentifier: Hashable {
    case ageRatingChange(ratingCode: Int)
    case manual(id: String)

    var cacheKey: String {
        switch self {
        case let .ageRatingChange(ratingCode):
            return "ageRatingChange.\(ratingCode)"
        case let .manual(id):
            return "manual.\(id)"
        }
    }

    var updateDescriptionFormatArguments: [CVarArg] {
        switch self {
        case let .ageRatingChange(ratingCode):
            return [ratingCode]
        case let .manual(id):
            return [id]
        }
    }
}

enum SignificantChangeConsentStatus: String {
    case granted
    case denied
}

protocol SignificantChangeConsentStoring {
    func status(for identifier: SignificantChangeIdentifier) -> SignificantChangeConsentStatus?
    func setStatus(_ status: SignificantChangeConsentStatus, for identifier: SignificantChangeIdentifier)
}

final class UserDefaultsSignificantChangeConsentStore: SignificantChangeConsentStoring {
    private enum Key {
        static let prefix = "com.woocommerce.ios.significantChangeConsent.status."
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
}
