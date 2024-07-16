import struct Yosemite.Site

/// AI-assisted features for product editing/creation.
enum ProductFormAIFeature: Equatable {
    case description
}

/// Checks the eligible AI features for product editing/creation.
final class ProductFormAIEligibilityChecker {
    private let site: Site?

    init(site: Site?) {
        self.site = site
    }

    /// Checks if an AI feature is enabled.
    /// - Parameter feature: AI-assisted feature.
    /// - Returns: Whether the feature is supported.
    func isFeatureEnabled(_ feature: ProductFormAIFeature) -> Bool {
        guard let site else {
            return false
        }

        return site.isWordPressComStore || site.isAIAssistantFeatureActive
    }
}
