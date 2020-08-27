@testable import WooCommerce

struct MockFeatureFlagService: FeatureFlagService {
    private let isEditProductsRelease3On: Bool

    init(isEditProductsRelease3On: Bool = false) {
        self.isEditProductsRelease3On = isEditProductsRelease3On
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .editProductsRelease3:
            return isEditProductsRelease3On
        default:
            return false
        }
    }
}
