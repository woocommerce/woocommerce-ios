@testable import WooCommerce

struct MockFeatureFlagService: FeatureFlagService {
    private let isEditProductsRelease2On: Bool
    private let isEditProductsRelease3On: Bool
    private let isInAppFeedbackOn: Bool

    init(isEditProductsRelease2On: Bool = false,
         isEditProductsRelease3On: Bool = false,
         isInAppFeedbackOn: Bool = false) {
        self.isEditProductsRelease2On = isEditProductsRelease2On
        self.isEditProductsRelease3On = isEditProductsRelease3On
        self.isInAppFeedbackOn = isInAppFeedbackOn
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .editProductsRelease2:
            return isEditProductsRelease2On
        case .editProductsRelease3:
            return isEditProductsRelease3On
        case .inAppFeedback:
            return isInAppFeedbackOn
        default:
            return false
        }
    }
}
