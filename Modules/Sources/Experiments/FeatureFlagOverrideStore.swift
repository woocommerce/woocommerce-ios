import Foundation

public protocol FeatureFlagOverrideStore {
    /// `nil` means "no override", caller should fall back to defaults.
    func overrideValue(for featureFlag: FeatureFlag) -> Bool?

    /// Pass `nil` to clear the override for that flag.
    func setOverrideValue(_ value: Bool?, for featureFlag: FeatureFlag)

    func removeAllOverrides()
}

public final class UserDefaultsFeatureFlagOverrideStore: FeatureFlagOverrideStore {
    private let userDefaults: UserDefaults
    private let keyPrefix: String
    private let lock = NSLock()

    public init(
        userDefaults: UserDefaults = .standard,
        keyPrefix: String = "com.woocommerce.featureflag.override."
    ) {
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix
    }

    public func overrideValue(for featureFlag: FeatureFlag) -> Bool? {
        lock.lock()
        defer { lock.unlock() }

        let key = storageKey(for: featureFlag)
        guard userDefaults.object(forKey: key) != nil else {
            return nil
        }
        return userDefaults.bool(forKey: key)
    }

    public func setOverrideValue(_ value: Bool?, for featureFlag: FeatureFlag) {
        lock.lock()
        defer { lock.unlock() }

        let key = storageKey(for: featureFlag)
        if let value {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }

    public func removeAllOverrides() {
        lock.lock()
        defer { lock.unlock() }

        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys where key.hasPrefix(keyPrefix) {
            userDefaults.removeObject(forKey: key)
        }
    }

    private func storageKey(for featureFlag: FeatureFlag) -> String {
        // Use case name (stable even if rawValues shift when adding cases).
        keyPrefix + String(describing: featureFlag)
    }
}
