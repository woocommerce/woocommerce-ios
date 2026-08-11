import Foundation

/// Defines the `actions` supported by the `FeatureFlagStore`.
///
public enum FeatureFlagAction: Action {
    case isRemoteFeatureFlagEnabled(_ featureFlag: RemoteFeatureFlag, defaultValue: Bool, useCache: Bool = true, completion: (Bool) -> Void)

    /// Reports the remote feature flag values the app is currently acting on, without triggering a fetch.
    ///
    /// `nil` when there are no usable values — no fetch has succeeded since launch, or the cached values have
    /// aged out. `isRemoteFeatureFlagEnabled` does not consult an expired cache: it refetches, and until that
    /// returns each caller falls back to its own default, so expired values are not what the app is acting on.
    ///
    /// For diagnostics. Callers deciding behaviour should keep using `isRemoteFeatureFlagEnabled`.
    ///
    case loadRemoteFeatureFlagsInEffect(completion: ([RemoteFeatureFlag: Bool]?) -> Void)
}
