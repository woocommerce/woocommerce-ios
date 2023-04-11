@testable import WooCommerce
import Experiments

struct MockFeatureFlagService: FeatureFlagService {
    private let isInboxOn: Bool
    private let isSplitViewInOrdersTabOn: Bool
    private let isUpdateOrderOptimisticallyOn: Bool
    private let shippingLabelsOnboardingM1: Bool
    private let isLoginPrologueOnboardingEnabled: Bool
    private let isStoreCreationMVPEnabled: Bool
    private let isStoreCreationM2Enabled: Bool
    private let isStoreCreationM2WithInAppPurchasesEnabled: Bool
    private let isDomainSettingsEnabled: Bool
    private let isSupportRequestEnabled: Bool
    private let isProductMultiSelectionM1Enabled: Bool
    private let isAddCouponToOrderEnabled: Bool
    private let isDashboardStoreOnboardingEnabled: Bool
    private let isFreeTrial: Bool
    private let jetpackSetupWithApplicationPassword: Bool
    private let isIPPUKExpansionEnabled: Bool

    init(isInboxOn: Bool = false,
         isSplitViewInOrdersTabOn: Bool = false,
         isUpdateOrderOptimisticallyOn: Bool = false,
         shippingLabelsOnboardingM1: Bool = false,
         isLoginPrologueOnboardingEnabled: Bool = false,
         isStoreCreationMVPEnabled: Bool = true,
         isStoreCreationM2Enabled: Bool = false,
         isStoreCreationM2WithInAppPurchasesEnabled: Bool = false,
         isDomainSettingsEnabled: Bool = false,
         isSupportRequestEnabled: Bool = false,
         isProductMultiSelectionM1Enabled: Bool = false,
         isAddCouponToOrderEnabled: Bool = false,
         isDashboardStoreOnboardingEnabled: Bool = false,
         isFreeTrial: Bool = false,
         jetpackSetupWithApplicationPassword: Bool = false,
         isIPPUKExpansionEnabled: Bool = false) {
        self.isInboxOn = isInboxOn
        self.isSplitViewInOrdersTabOn = isSplitViewInOrdersTabOn
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
        self.shippingLabelsOnboardingM1 = shippingLabelsOnboardingM1
        self.isLoginPrologueOnboardingEnabled = isLoginPrologueOnboardingEnabled
        self.isStoreCreationMVPEnabled = isStoreCreationMVPEnabled
        self.isStoreCreationM2Enabled = isStoreCreationM2Enabled
        self.isStoreCreationM2WithInAppPurchasesEnabled = isStoreCreationM2WithInAppPurchasesEnabled
        self.isDomainSettingsEnabled = isDomainSettingsEnabled
        self.isSupportRequestEnabled = isSupportRequestEnabled
        self.isProductMultiSelectionM1Enabled = isProductMultiSelectionM1Enabled
        self.isAddCouponToOrderEnabled = isAddCouponToOrderEnabled
        self.isDashboardStoreOnboardingEnabled = isDashboardStoreOnboardingEnabled
        self.isFreeTrial = isFreeTrial
        self.jetpackSetupWithApplicationPassword = jetpackSetupWithApplicationPassword
        self.isIPPUKExpansionEnabled = isIPPUKExpansionEnabled
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
        case .storeCreationMVP:
            return isStoreCreationMVPEnabled
        case .storeCreationM2:
            return isStoreCreationM2Enabled
        case .storeCreationM2WithInAppPurchasesEnabled:
            return isStoreCreationM2WithInAppPurchasesEnabled
        case .domainSettings:
            return isDomainSettingsEnabled
        case .supportRequests:
            return isSupportRequestEnabled
        case .productMultiSelectionM1:
            return isProductMultiSelectionM1Enabled
        case .addCouponToOrder:
            return isAddCouponToOrderEnabled
        case .dashboardOnboarding:
            return isDashboardStoreOnboardingEnabled
        case .freeTrial:
            return isFreeTrial
        case .jetpackSetupWithApplicationPassword:
            return jetpackSetupWithApplicationPassword
        case .IPPUKExpansion:
            return isIPPUKExpansionEnabled
        default:
            return false
        }
    }
}
