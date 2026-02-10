import Foundation

/// Protocol for overriding remote feature flag values for development/testing purposes.
public protocol RemoteFeatureFlagOverrideStore {
    /// `nil` means "no override", caller should fall back to remote/default value.
    func overrideValue(for featureFlag: RemoteFeatureFlag) -> Bool?

    /// Pass `nil` to clear the override for that flag.
    func setOverrideValue(_ value: Bool?, for featureFlag: RemoteFeatureFlag)

    func removeAllOverrides()
}
