@testable import WooCommerce
import Experiments

struct MockFeatureFlagService: FeatureFlagService {
    private let isJetpackConnectionPackageSupportOn: Bool
    private let isInboxOn: Bool
    private let isSplitViewInOrdersTabOn: Bool
    private let isUpdateOrderOptimisticallyOn: Bool
    private let shippingLabelsOnboardingM1: Bool
    private let isAppleIDAccountDeletionEnabled: Bool
    private let isBackgroundImageUploadEnabled: Bool
    private let isLoginPrologueOnboardingEnabled: Bool

    init(isJetpackConnectionPackageSupportOn: Bool = false,
         isInboxOn: Bool = false,
         isSplitViewInOrdersTabOn: Bool = false,
         isUpdateOrderOptimisticallyOn: Bool = false,
         shippingLabelsOnboardingM1: Bool = false,
         isAppleIDAccountDeletionEnabled: Bool = false,
         isBackgroundImageUploadEnabled: Bool = false,
         isLoginPrologueOnboardingEnabled: Bool = false) {
        self.isJetpackConnectionPackageSupportOn = isJetpackConnectionPackageSupportOn
        self.isInboxOn = isInboxOn
        self.isSplitViewInOrdersTabOn = isSplitViewInOrdersTabOn
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
        self.shippingLabelsOnboardingM1 = shippingLabelsOnboardingM1
        self.isAppleIDAccountDeletionEnabled = isAppleIDAccountDeletionEnabled
        self.isBackgroundImageUploadEnabled = isBackgroundImageUploadEnabled
        self.isLoginPrologueOnboardingEnabled = isLoginPrologueOnboardingEnabled
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .jetpackConnectionPackageSupport:
            return isJetpackConnectionPackageSupportOn
        case .inbox:
            return isInboxOn
        case .splitViewInOrdersTab:
            return isSplitViewInOrdersTabOn
        case .updateOrderOptimistically:
            return isUpdateOrderOptimisticallyOn
        case .shippingLabelsOnboardingM1:
            return shippingLabelsOnboardingM1
        case .appleIDAccountDeletion:
            return isAppleIDAccountDeletionEnabled
        case .backgroundProductImageUpload:
            return isBackgroundImageUploadEnabled
        case .loginPrologueOnboarding:
            return isLoginPrologueOnboardingEnabled
        default:
            return false
        }
    }
}
