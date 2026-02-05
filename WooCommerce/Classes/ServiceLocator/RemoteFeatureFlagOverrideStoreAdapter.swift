import Foundation
import Experiments
import Networking

/// Adapter that bridges `FeatureFlagOverrideStore` (from Experiments) to work with `RemoteFeatureFlag` (from Networking).
/// This allows the same UserDefaults-based storage to be used for both local and remote feature flag overrides.
final class RemoteFeatureFlagOverrideStoreAdapter: RemoteFeatureFlagOverrideStore {
    private let baseStore: FeatureFlagOverrideStore

    init(baseStore: FeatureFlagOverrideStore) {
        self.baseStore = baseStore
    }

    func overrideValue(for featureFlag: RemoteFeatureFlag) -> Bool? {
        baseStore.overrideValue(forKey: storageKey(for: featureFlag))
    }

    func setOverrideValue(_ value: Bool?, for featureFlag: RemoteFeatureFlag) {
        baseStore.setOverrideValue(value, forKey: storageKey(for: featureFlag))
    }

    func removeAllOverrides() {
        baseStore.removeAllOverrides()
    }

    private func storageKey(for featureFlag: RemoteFeatureFlag) -> String {
        "remote.\(String(describing: featureFlag))"
    }
}
