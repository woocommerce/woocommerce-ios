@testable import WooCommerce
import Experiments

struct MockFeatureFlagService: FeatureFlagService {
    private let isInboxOn: Bool
    private let isSplitViewInOrdersTabOn: Bool
    private let isUpdateOrderOptimisticallyOn: Bool
    private let shippingLabelsOnboardingM1: Bool
    private let isDomainSettingsEnabled: Bool
    private let isSupportRequestEnabled: Bool
    private let isDashboardStoreOnboardingEnabled: Bool
    private let jetpackSetupWithApplicationPassword: Bool
    private let isProductDescriptionAIEnabled: Bool
    private let isProductDescriptionAIFromStoreOnboardingEnabled: Bool
    private let isReadOnlyGiftCardsEnabled: Bool
    private let isHideStoreOnboardingTaskListFeatureEnabled: Bool
    private let isAddProductToOrderViaSKUScannerEnabled: Bool
    private let isBlazeEnabled: Bool
    private let isShareProductAIEnabled: Bool
    private let betterCustomerSelectionInOrder: Bool
    private let productCreationAI: Bool
    private let productBundles: Bool
    private let productBundlesInOrderForm: Bool
    private let isLightweightStorefrontEnabled: Bool

    init(isInboxOn: Bool = false,
         isSplitViewInOrdersTabOn: Bool = false,
         isUpdateOrderOptimisticallyOn: Bool = false,
         shippingLabelsOnboardingM1: Bool = false,
         isDomainSettingsEnabled: Bool = false,
         isSupportRequestEnabled: Bool = false,
         isDashboardStoreOnboardingEnabled: Bool = false,
         jetpackSetupWithApplicationPassword: Bool = false,
         isProductDescriptionAIEnabled: Bool = false,
         isProductDescriptionAIFromStoreOnboardingEnabled: Bool = false,
         isReadOnlyGiftCardsEnabled: Bool = false,
         isHideStoreOnboardingTaskListFeatureEnabled: Bool = false,
         isAddProductToOrderViaSKUScannerEnabled: Bool = false,
         isBlazeEnabled: Bool = false,
         isShareProductAIEnabled: Bool = false,
         betterCustomerSelectionInOrder: Bool = false,
         productCreationAI: Bool = false,
         productBundles: Bool = false,
         productBundlesInOrderForm: Bool = false,
         isLightweightStorefrontEnabled: Bool = false) {
        self.isInboxOn = isInboxOn
        self.isSplitViewInOrdersTabOn = isSplitViewInOrdersTabOn
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
        self.shippingLabelsOnboardingM1 = shippingLabelsOnboardingM1
        self.isDomainSettingsEnabled = isDomainSettingsEnabled
        self.isSupportRequestEnabled = isSupportRequestEnabled
        self.isDashboardStoreOnboardingEnabled = isDashboardStoreOnboardingEnabled
        self.jetpackSetupWithApplicationPassword = jetpackSetupWithApplicationPassword
        self.isProductDescriptionAIEnabled = isProductDescriptionAIEnabled
        self.isProductDescriptionAIFromStoreOnboardingEnabled = isProductDescriptionAIFromStoreOnboardingEnabled
        self.isReadOnlyGiftCardsEnabled = isReadOnlyGiftCardsEnabled
        self.isHideStoreOnboardingTaskListFeatureEnabled = isHideStoreOnboardingTaskListFeatureEnabled
        self.isAddProductToOrderViaSKUScannerEnabled = isAddProductToOrderViaSKUScannerEnabled
        self.isBlazeEnabled = isBlazeEnabled
        self.isShareProductAIEnabled = isShareProductAIEnabled
        self.betterCustomerSelectionInOrder = betterCustomerSelectionInOrder
        self.productCreationAI = productCreationAI
        self.productBundles = productBundles
        self.productBundlesInOrderForm = productBundlesInOrderForm
        self.isLightweightStorefrontEnabled = isLightweightStorefrontEnabled
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
        case .domainSettings:
            return isDomainSettingsEnabled
        case .supportRequests:
            return isSupportRequestEnabled
        case .dashboardOnboarding:
            return isDashboardStoreOnboardingEnabled
        case .jetpackSetupWithApplicationPassword:
            return jetpackSetupWithApplicationPassword
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
        case .betterCustomerSelectionInOrder:
            return betterCustomerSelectionInOrder
        case .productCreationAI:
            return productCreationAI
        case .productBundles:
            return productBundles
        case .productBundlesInOrderForm:
            return productBundlesInOrderForm
        case .lightweightStorefront:
            return isLightweightStorefrontEnabled
        default:
            return false
        }
    }
}
