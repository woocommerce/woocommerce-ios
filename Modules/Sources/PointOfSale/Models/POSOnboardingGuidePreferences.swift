import Foundation

protocol POSOnboardingGuidePreferenceStoring {
    func hasCompletedGuide(for siteID: Int64) -> Bool
    func markGuideCompleted(for siteID: Int64)
}

struct POSOnboardingGuidePreferences: POSOnboardingGuidePreferenceStoring {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func hasCompletedGuide(for siteID: Int64) -> Bool {
        userDefaults.bool(forKey: POSOnboardingGuidePersistence.key(for: siteID))
    }

    func markGuideCompleted(for siteID: Int64) {
        userDefaults.set(true, forKey: POSOnboardingGuidePersistence.key(for: siteID))
    }
}

/// Logout is owned by the app target, which must clear completion for every store visited this session.
public enum POSOnboardingGuidePersistence {
    private static let keyPrefix = "com.woocommerce.pos.onboardingGuide.completed."

    static func key(for siteID: Int64) -> String {
        keyPrefix + String(siteID)
    }

    public static func clearAll(userDefaults: UserDefaults = .standard) {
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix(keyPrefix) {
            userDefaults.removeObject(forKey: key)
        }
    }
}
