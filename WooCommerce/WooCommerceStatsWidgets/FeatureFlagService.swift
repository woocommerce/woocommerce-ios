import Foundation

/// Ideally we use the Feature Flag implementation from the Experiments target, but it failed to compile when importing.
/// We should fix it and use it here.
struct FeatureFlagService {
    let widgetsFeatureIsEnabled = true
}
