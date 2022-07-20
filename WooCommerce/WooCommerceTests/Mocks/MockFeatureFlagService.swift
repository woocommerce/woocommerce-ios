@testable import WooCommerce
import Experiments

struct MockFeatureFlagService: FeatureFlagService {
    private let isJetpackConnectionPackageSupportOn: Bool
    private let isHubMenuOn: Bool
    private let isInboxOn: Bool
    private let isSplitViewInOrdersTabOn: Bool
    private let isUpdateOrderOptimisticallyOn: Bool
    private let shippingLabelsOnboardingM1: Bool
    private let inPersonPaymentGatewaySelection: Bool
    private let isAppleIDAccountDeletionEnabled: Bool
    private let isBackgroundImageUploadEnabled: Bool

    init(isJetpackConnectionPackageSupportOn: Bool = false,
         isHubMenuOn: Bool = false,
         isInboxOn: Bool = false,
         isSplitViewInOrdersTabOn: Bool = false,
         isUpdateOrderOptimisticallyOn: Bool = false,
         shippingLabelsOnboardingM1: Bool = false,
         inPersonPaymentGatewaySelection: Bool = false,
         isAppleIDAccountDeletionEnabled: Bool = false,
         isBackgroundImageUploadEnabled: Bool = false) {
        self.isJetpackConnectionPackageSupportOn = isJetpackConnectionPackageSupportOn
        self.isHubMenuOn = isHubMenuOn
        self.isInboxOn = isInboxOn
        self.isSplitViewInOrdersTabOn = isSplitViewInOrdersTabOn
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
        self.shippingLabelsOnboardingM1 = shippingLabelsOnboardingM1
        self.inPersonPaymentGatewaySelection = inPersonPaymentGatewaySelection
        self.isAppleIDAccountDeletionEnabled = isAppleIDAccountDeletionEnabled
        self.isBackgroundImageUploadEnabled = isBackgroundImageUploadEnabled
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .jetpackConnectionPackageSupport:
            return isJetpackConnectionPackageSupportOn
        case .hubMenu:
            return isHubMenuOn
        case .inbox:
            return isInboxOn
        case .splitViewInOrdersTab:
            return isSplitViewInOrdersTabOn
        case .updateOrderOptimistically:
            return isUpdateOrderOptimisticallyOn
        case .shippingLabelsOnboardingM1:
            return shippingLabelsOnboardingM1
        case .inPersonPaymentGatewaySelection:
            return inPersonPaymentGatewaySelection
        case .appleIDAccountDeletion:
            return isAppleIDAccountDeletionEnabled
        case .backgroundProductImageUpload:
            return isBackgroundImageUploadEnabled
        default:
            return false
        }
    }
}
