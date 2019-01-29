/// FeatureFlag exposes a series of features to be conditionally enabled on
/// different builds.
enum FeatureFlag: Int {
    case appReviewPrompt

    /// Returns a boolean indicating if the feature is enabled
    var enabled: Bool {
        switch self {
        case .appReviewPrompt:
            return BuildConfiguration.current == .localDeveloper
        }
    }
}
