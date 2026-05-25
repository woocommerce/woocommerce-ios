import Foundation

public protocol FeatureFlagOverrideStore {
    /// `nil` means "no override", caller should fall back to defaults.
    func overrideValue(for featureFlag: FeatureFlag) -> Bool?

    /// Pass `nil` to clear the override for that flag.
    func setOverrideValue(_ value: Bool?, for featureFlag: FeatureFlag)

    /// `nil` means "no override", caller should fall back to defaults.
    /// Use this for any flag type by providing a string key.
    func overrideValue(forKey key: String) -> Bool?

    /// Pass `nil` to clear the override for that key.
    /// Use this for any flag type by providing a string key.
    func setOverrideValue(_ value: Bool?, forKey key: String)

    func removeAllOverrides()
}

public final class UserDefaultsFeatureFlagOverrideStore: FeatureFlagOverrideStore {
    private let userDefaults: UserDefaults
    private let keyPrefix: String
    private let queue = DispatchQueue(label: "com.woocommerce.featureflag.override-store")

    public init(
        userDefaults: UserDefaults = .standard,
        keyPrefix: String = "com.woocommerce.featureflag.override."
    ) {
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix
    }

    public func overrideValue(for featureFlag: FeatureFlag) -> Bool? {
        overrideValue(forKey: String(describing: featureFlag))
    }

    public func setOverrideValue(_ value: Bool?, for featureFlag: FeatureFlag) {
        setOverrideValue(value, forKey: String(describing: featureFlag))
    }

    public func overrideValue(forKey key: String) -> Bool? {
        queue.sync {
            let fullKey = keyPrefix + key
            guard userDefaults.object(forKey: fullKey) != nil else {
                return nil
            }
            return userDefaults.bool(forKey: fullKey)
        }
    }

    public func setOverrideValue(_ value: Bool?, forKey key: String) {
        queue.sync {
            let fullKey = keyPrefix + key
            if let value {
                userDefaults.set(value, forKey: fullKey)
            } else {
                userDefaults.removeObject(forKey: fullKey)
            }
        }
    }

    public func removeAllOverrides() {
        queue.sync {
            let keys = userDefaults.dictionaryRepresentation().keys
            for key in keys where key.hasPrefix(keyPrefix) {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
}
