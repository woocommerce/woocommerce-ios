@testable import WooCommerce
import Experiments

struct MockFeatureFlagService: FeatureFlagService {
    private let isInboxOn: Bool
    private let isSplitViewInOrdersTabOn: Bool
    private let isUpdateOrderOptimisticallyOn: Bool
    private let shippingLabelsOnboardingM1: Bool
    private let isLoginPrologueOnboardingEnabled: Bool
    private let isSimplifiedLoginFlowI1Enabled: Bool
    private let isProductsOnboardingEnabled: Bool

    init(isInboxOn: Bool = false,
         isSplitViewInOrdersTabOn: Bool = false,
         isUpdateOrderOptimisticallyOn: Bool = false,
         shippingLabelsOnboardingM1: Bool = false,
         isLoginPrologueOnboardingEnabled: Bool = false,
         isSimplifiedLoginFlowI1Enabled: Bool = false,
         isProductsOnboardingEnabled: Bool = false) {
        self.isInboxOn = isInboxOn
        self.isSplitViewInOrdersTabOn = isSplitViewInOrdersTabOn
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
        self.shippingLabelsOnboardingM1 = shippingLabelsOnboardingM1
        self.isLoginPrologueOnboardingEnabled = isLoginPrologueOnboardingEnabled
        self.isSimplifiedLoginFlowI1Enabled = isSimplifiedLoginFlowI1Enabled
        self.isProductsOnboardingEnabled = isProductsOnboardingEnabled
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .inbox:
            return isInboxOn
        case .splitViewInOrdersTab:
            return isSplitViewInOrdersTabOn
        case .updateOrderOptimistically:
            return isUpdateOrderOptimisticallyOn
        case .shippingLabelsOnboardingM1:
            return shippingLabelsOnboardingM1
        case .loginPrologueOnboarding:
            return isLoginPrologueOnboardingEnabled
        case .simplifiedLoginFlowI1:
            return isSimplifiedLoginFlowI1Enabled
        case .productsOnboarding:
            return isProductsOnboardingEnabled
        default:
            return false
        }
    }
}
