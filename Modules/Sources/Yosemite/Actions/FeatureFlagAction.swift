import Foundation

/// Defines the `actions` supported by the `FeatureFlagStore`.
///
public enum FeatureFlagAction: Action {
    case isRemoteFeatureFlagEnabled(_ featureFlag: RemoteFeatureFlag, defaultValue: Bool, useCache: Bool = true, completion: (Bool) -> Void)
}
