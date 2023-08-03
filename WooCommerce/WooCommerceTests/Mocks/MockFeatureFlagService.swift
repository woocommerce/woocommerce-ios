@testable import WooCommerce
import Experiments

struct MockFeatureFlagService: FeatureFlagService {
    private let isInboxOn: Bool
    private let isSplitViewInOrdersTabOn: Bool
    private let isUpdateOrderOptimisticallyOn: Bool
    private let shippingLabelsOnboardingM1: Bool
    private let isLoginPrologueOnboardingEnabled: Bool
    private let isDomainSettingsEnabled: Bool
    private let isSupportRequestEnabled: Bool
    private let isDashboardStoreOnboardingEnabled: Bool
    private let jetpackSetupWithApplicationPassword: Bool
    private let isTapToPayOnIPhoneMilestone2On: Bool
    private let isReadOnlySubscriptionsEnabled: Bool
    private let isProductDescriptionAIEnabled: Bool
    private let isProductDescriptionAIFromStoreOnboardingEnabled: Bool
    private let isReadOnlyGiftCardsEnabled: Bool
    private let isHideStoreOnboardingTaskListFeatureEnabled: Bool
    private let isAddProductToOrderViaSKUScannerEnabled: Bool
    private let isBlazeEnabled: Bool
    private let isShareProductAIEnabled: Bool
    private let isJustInTimeMessagesOnDashboardEnabled: Bool
    private let isFreeTrialInAppPurchasesUpgradeM2: Bool
    private let betterCustomerSelectionInOrder: Bool
    private let optimizeProfilerQuestions: Bool

    init(isInboxOn: Bool = false,
         isSplitViewInOrdersTabOn: Bool = false,
         isUpdateOrderOptimisticallyOn: Bool = false,
         shippingLabelsOnboardingM1: Bool = false,
         isLoginPrologueOnboardingEnabled: Bool = false,
         isDomainSettingsEnabled: Bool = false,
         isSupportRequestEnabled: Bool = false,
         isDashboardStoreOnboardingEnabled: Bool = false,
         jetpackSetupWithApplicationPassword: Bool = false,
         isTapToPayOnIPhoneMilestone2On: Bool = false,
         isReadOnlySubscriptionsEnabled: Bool = false,
         isProductDescriptionAIEnabled: Bool = false,
         isProductDescriptionAIFromStoreOnboardingEnabled: Bool = false,
         isReadOnlyGiftCardsEnabled: Bool = false,
         isHideStoreOnboardingTaskListFeatureEnabled: Bool = false,
         isAddProductToOrderViaSKUScannerEnabled: Bool = false,
         isBlazeEnabled: Bool = false,
         isShareProductAIEnabled: Bool = false,
         isJustInTimeMessagesOnDashboardEnabled: Bool = false,
         isFreeTrialInAppPurchasesUpgradeM2: Bool = false,
         betterCustomerSelectionInOrder: Bool = false,
         optimizeProfilerQuestions: Bool = false) {
        self.isInboxOn = isInboxOn
        self.isSplitViewInOrdersTabOn = isSplitViewInOrdersTabOn
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
        self.shippingLabelsOnboardingM1 = shippingLabelsOnboardingM1
        self.isLoginPrologueOnboardingEnabled = isLoginPrologueOnboardingEnabled
        self.isDomainSettingsEnabled = isDomainSettingsEnabled
        self.isSupportRequestEnabled = isSupportRequestEnabled
        self.isDashboardStoreOnboardingEnabled = isDashboardStoreOnboardingEnabled
        self.isFreeTrialInAppPurchasesUpgradeM2 = isFreeTrialInAppPurchasesUpgradeM2
        self.jetpackSetupWithApplicationPassword = jetpackSetupWithApplicationPassword
        self.isTapToPayOnIPhoneMilestone2On = isTapToPayOnIPhoneMilestone2On
        self.isReadOnlySubscriptionsEnabled = isReadOnlySubscriptionsEnabled
        self.isProductDescriptionAIEnabled = isProductDescriptionAIEnabled
        self.isProductDescriptionAIFromStoreOnboardingEnabled = isProductDescriptionAIFromStoreOnboardingEnabled
        self.isReadOnlyGiftCardsEnabled = isReadOnlyGiftCardsEnabled
        self.isHideStoreOnboardingTaskListFeatureEnabled = isHideStoreOnboardingTaskListFeatureEnabled
        self.isAddProductToOrderViaSKUScannerEnabled = isAddProductToOrderViaSKUScannerEnabled
        self.isBlazeEnabled = isBlazeEnabled
        self.isShareProductAIEnabled = isShareProductAIEnabled
        self.isJustInTimeMessagesOnDashboardEnabled = isJustInTimeMessagesOnDashboardEnabled
        self.betterCustomerSelectionInOrder = betterCustomerSelectionInOrder
        self.optimizeProfilerQuestions = optimizeProfilerQuestions
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
        case .domainSettings:
            return isDomainSettingsEnabled
        case .supportRequests:
            return isSupportRequestEnabled
        case .dashboardOnboarding:
            return isDashboardStoreOnboardingEnabled
        case .jetpackSetupWithApplicationPassword:
            return jetpackSetupWithApplicationPassword
        case .tapToPayOnIPhoneMilestone2:
            return isTapToPayOnIPhoneMilestone2On
        case .readOnlySubscriptions:
            return isReadOnlySubscriptionsEnabled
        case .productDescriptionAI:
            return isProductDescriptionAIEnabled
        case .productDescriptionAIFromStoreOnboarding:
            return isProductDescriptionAIFromStoreOnboardingEnabled
        case .readOnlyGiftCards:
            return isReadOnlyGiftCardsEnabled
        case .hideStoreOnboardingTaskList:
            return isHideStoreOnboardingTaskListFeatureEnabled
        case .addProductToOrderViaSKUScanner:
            return isAddProductToOrderViaSKUScannerEnabled
        case .shareProductAI:
            return isShareProductAIEnabled
        case .justInTimeMessagesOnDashboard:
            return isJustInTimeMessagesOnDashboardEnabled
        case .freeTrialInAppPurchasesUpgradeM2:
            return isFreeTrialInAppPurchasesUpgradeM2
        case .betterCustomerSelectionInOrder:
            return betterCustomerSelectionInOrder
        case .optimizeProfilerQuestions:
            return optimizeProfilerQuestions
        default:
            return false
        }
    }
}
