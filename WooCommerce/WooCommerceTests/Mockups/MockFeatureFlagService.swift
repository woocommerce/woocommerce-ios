@testable import WooCommerce

struct MockFeatureFlagService: FeatureFlagService {
    private let isEditProductsRelease2On: Bool
    private let isEditProductsRelease3On: Bool

    init(isEditProductsRelease2On: Bool = false,
         isEditProductsRelease3On: Bool = false) {
        self.isEditProductsRelease2On = isEditProductsRelease2On
        self.isEditProductsRelease3On = isEditProductsRelease3On
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .editProductsRelease2:
            return isEditProductsRelease2On
        case .editProductsRelease3:
            return isEditProductsRelease3On
        default:
            return false
        }
    }
}
