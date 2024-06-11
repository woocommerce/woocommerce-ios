@testable import WooCommerce
import Experiments

struct MockFeatureFlagService: FeatureFlagService {
    private let isInboxOn: Bool
    private let isUpdateOrderOptimisticallyOn: Bool
    private let shippingLabelsOnboardingM1: Bool
    private let isDomainSettingsEnabled: Bool
    private let isSupportRequestEnabled: Bool
    private let jetpackSetupWithApplicationPassword: Bool
    private let isProductDescriptionAIEnabled: Bool
    private let isProductDescriptionAIFromStoreOnboardingEnabled: Bool
    private let isReadOnlyGiftCardsEnabled: Bool
    private let isBlazeEnabled: Bool
    private let isShareProductAIEnabled: Bool
    private let betterCustomerSelectionInOrder: Bool
    private let productCreationAI: Bool
    private let productBundles: Bool
    private let productBundlesInOrderForm: Bool
    private let isScanToUpdateInventoryEnabled: Bool
    private let blazei3NativeCampaignCreation: Bool
    private let isBackendReceiptsEnabled: Bool
    private let sideBySideViewForOrderForm: Bool
    private let isSubscriptionsInOrderCreationCustomersEnabled: Bool
    private let isDisplayPointOfSaleToggleEnabled: Bool
    private let isDynamicDashboardM2Enabled: Bool

    init(isInboxOn: Bool = false,
         isUpdateOrderOptimisticallyOn: Bool = false,
         shippingLabelsOnboardingM1: Bool = false,
         isDomainSettingsEnabled: Bool = false,
         isSupportRequestEnabled: Bool = false,
         jetpackSetupWithApplicationPassword: Bool = false,
         isProductDescriptionAIEnabled: Bool = false,
         isProductDescriptionAIFromStoreOnboardingEnabled: Bool = false,
         isReadOnlyGiftCardsEnabled: Bool = false,
         isBlazeEnabled: Bool = false,
         isShareProductAIEnabled: Bool = false,
         betterCustomerSelectionInOrder: Bool = false,
         productCreationAI: Bool = false,
         productBundles: Bool = false,
         productBundlesInOrderForm: Bool = false,
         isScanToUpdateInventoryEnabled: Bool = false,
         blazei3NativeCampaignCreation: Bool = false,
         isBackendReceiptsEnabled: Bool = false,
         sideBySideViewForOrderForm: Bool = false,
         isSubscriptionsInOrderCreationCustomersEnabled: Bool = false,
         isDisplayPointOfSaleToggleEnabled: Bool = false,
         isDynamicDashboardM2Enabled: Bool = false) {
        self.isInboxOn = isInboxOn
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
        self.shippingLabelsOnboardingM1 = shippingLabelsOnboardingM1
        self.isDomainSettingsEnabled = isDomainSettingsEnabled
        self.isSupportRequestEnabled = isSupportRequestEnabled
        self.jetpackSetupWithApplicationPassword = jetpackSetupWithApplicationPassword
        self.isProductDescriptionAIEnabled = isProductDescriptionAIEnabled
        self.isProductDescriptionAIFromStoreOnboardingEnabled = isProductDescriptionAIFromStoreOnboardingEnabled
        self.isReadOnlyGiftCardsEnabled = isReadOnlyGiftCardsEnabled
        self.isBlazeEnabled = isBlazeEnabled
        self.isShareProductAIEnabled = isShareProductAIEnabled
        self.betterCustomerSelectionInOrder = betterCustomerSelectionInOrder
        self.productCreationAI = productCreationAI
        self.productBundles = productBundles
        self.productBundlesInOrderForm = productBundlesInOrderForm
        self.isScanToUpdateInventoryEnabled = isScanToUpdateInventoryEnabled
        self.blazei3NativeCampaignCreation = blazei3NativeCampaignCreation
        self.isBackendReceiptsEnabled = isBackendReceiptsEnabled
        self.sideBySideViewForOrderForm = sideBySideViewForOrderForm
        self.isSubscriptionsInOrderCreationCustomersEnabled = isSubscriptionsInOrderCreationCustomersEnabled
        self.isDisplayPointOfSaleToggleEnabled = isDisplayPointOfSaleToggleEnabled
        self.isDynamicDashboardM2Enabled = isDynamicDashboardM2Enabled
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .inbox:
            return isInboxOn
        case .updateOrderOptimistically:
            return isUpdateOrderOptimisticallyOn
        case .shippingLabelsOnboardingM1:
            return shippingLabelsOnboardingM1
        case .domainSettings:
            return isDomainSettingsEnabled
        case .supportRequests:
            return isSupportRequestEnabled
        case .jetpackSetupWithApplicationPassword:
            return jetpackSetupWithApplicationPassword
        case .productDescriptionAI:
            return isProductDescriptionAIEnabled
        case .productDescriptionAIFromStoreOnboarding:
            return isProductDescriptionAIFromStoreOnboardingEnabled
        case .readOnlyGiftCards:
            return isReadOnlyGiftCardsEnabled
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
        case .scanToUpdateInventory:
            return isScanToUpdateInventoryEnabled
        case .blazei3NativeCampaignCreation:
            return blazei3NativeCampaignCreation
        case .backendReceipts:
            return isBackendReceiptsEnabled
        case .sideBySideViewForOrderForm:
            return sideBySideViewForOrderForm
        case .subscriptionsInOrderCreationCustomers:
            return isSubscriptionsInOrderCreationCustomersEnabled
        case .displayPointOfSaleToggle:
            return isDisplayPointOfSaleToggleEnabled
        case .dynamicDashboardM2:
            return isDynamicDashboardM2Enabled
        default:
            return false
        }
    }
}
