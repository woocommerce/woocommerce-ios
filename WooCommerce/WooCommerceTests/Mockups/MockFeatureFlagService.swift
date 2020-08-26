@testable import WooCommerce

struct MockFeatureFlagService: FeatureFlagService {
    private let isEditProductsRelease3On: Bool
    private let isInAppFeedbackOn: Bool

    init(isEditProductsRelease3On: Bool = false,
         isInAppFeedbackOn: Bool = false) {
        self.isEditProductsRelease3On = isEditProductsRelease3On
        self.isInAppFeedbackOn = isInAppFeedbackOn
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .editProductsRelease3:
            return isEditProductsRelease3On
        case .inAppFeedback:
            return isInAppFeedbackOn
        default:
            return false
        }
    }
}
