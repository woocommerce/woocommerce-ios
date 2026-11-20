import Foundation

protocol POSCustomAmountTaxPreferenceStoring {
    func isTaxable(for siteID: Int64) -> Bool
    func setTaxable(_ isTaxable: Bool, for siteID: Int64)
}

struct POSCustomAmountTaxPreferences: POSCustomAmountTaxPreferenceStoring {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func isTaxable(for siteID: Int64) -> Bool {
        userDefaults.bool(forKey: POSCustomAmountTaxPersistence.key(for: siteID))
    }

    func setTaxable(_ isTaxable: Bool, for siteID: Int64) {
        userDefaults.set(isTaxable, forKey: POSCustomAmountTaxPersistence.key(for: siteID))
    }
}

/// Logout is owned by the app target, which must clear preferences for every store visited this session.
public enum POSCustomAmountTaxPersistence {
    private static let keyPrefix = "com.woocommerce.pos.customAmount.lastTaxable."

    static func key(for siteID: Int64) -> String {
        keyPrefix + String(siteID)
    }

    public static func clearAll(userDefaults: UserDefaults = .standard) {
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix(keyPrefix) {
            userDefaults.removeObject(forKey: key)
        }
    }
}
