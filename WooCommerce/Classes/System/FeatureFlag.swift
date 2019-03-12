/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
enum FeatureFlag: Int {
    /// Throwaway case, to prevent a compiler error:
    /// `An enum with no cases cannot declare a raw type`
    case null
    case manualTracking

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .manualTracking:
            return BuildConfiguration.current == .localDeveloper

        default:
            return true
        }
    }
}
