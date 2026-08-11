import Foundation

/// Checks remote feature flags through an async interface, wrapping `FeatureFlagAction` dispatch
/// so callers don't need to hand-roll continuations around the completion-based action.
public protocol RemoteFeatureFlagServiceProtocol {
    /// Returns whether the given remote feature flag is enabled, resolving in order:
    /// override store → in-memory cache (when `useCache` is true) → network → `defaultValue` on failure.
    /// - Parameters:
    ///   - featureFlag: The remote feature flag to check.
    ///   - defaultValue: The value returned when the flag cannot be resolved (e.g. network failure).
    ///   - useCache: Whether a previously fetched value within the cache window can be reused.
    func isEnabled(_ featureFlag: RemoteFeatureFlag, defaultValue: Bool, useCache: Bool) async -> Bool
}

public extension RemoteFeatureFlagServiceProtocol {
    /// Convenience overload reusing the cached value when available, matching `FeatureFlagAction`'s default.
    func isEnabled(_ featureFlag: RemoteFeatureFlag, defaultValue: Bool) async -> Bool {
        await isEnabled(featureFlag, defaultValue: defaultValue, useCache: true)
    }
}

public struct RemoteFeatureFlagService: RemoteFeatureFlagServiceProtocol {
    private let stores: StoresManager

    public init(stores: StoresManager) {
        self.stores = stores
    }

    @MainActor
    public func isEnabled(_ featureFlag: RemoteFeatureFlag, defaultValue: Bool, useCache: Bool) async -> Bool {
        await withCheckedContinuation { continuation in
            let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(featureFlag,
                                                                      defaultValue: defaultValue,
                                                                      useCache: useCache) { isEnabled in
                continuation.resume(returning: isEnabled)
            }
            stores.dispatch(action)
        }
    }
}
