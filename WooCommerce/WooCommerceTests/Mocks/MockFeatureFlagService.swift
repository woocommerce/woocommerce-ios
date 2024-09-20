@testable import WooCommerce
import Experiments

struct MockFeatureFlagService: FeatureFlagService {
    private let isInboxOn: Bool
    private let isShowInboxCTAEnabled: Bool
    private let isUpdateOrderOptimisticallyOn: Bool
    private let shippingLabelsOnboardingM1: Bool
    private let isDomainSettingsEnabled: Bool
    private let isSupportRequestEnabled: Bool
    private let jetpackSetupWithApplicationPassword: Bool
    private let betterCustomerSelectionInOrder: Bool
    private let productBundlesInOrderForm: Bool
    private let isScanToUpdateInventoryEnabled: Bool
    private let isBackendReceiptsEnabled: Bool
    private let sideBySideViewForOrderForm: Bool
    private let isSubscriptionsInOrderCreationCustomersEnabled: Bool
    private let isPointOfSaleEnabled: Bool
    private let googleAdsCampaignCreationOnWebView: Bool
    private let blazeEvergreenCampaigns: Bool
    private let blazeCampaignObjective: Bool
    private let revampedShippingLabelCreation: Bool

    init(isInboxOn: Bool = false,
         isShowInboxCTAEnabled: Bool = false,
         isUpdateOrderOptimisticallyOn: Bool = false,
         shippingLabelsOnboardingM1: Bool = false,
         isDomainSettingsEnabled: Bool = false,
         isSupportRequestEnabled: Bool = false,
         jetpackSetupWithApplicationPassword: Bool = false,
         betterCustomerSelectionInOrder: Bool = false,
         productBundlesInOrderForm: Bool = false,
         isScanToUpdateInventoryEnabled: Bool = false,
         isBackendReceiptsEnabled: Bool = false,
         sideBySideViewForOrderForm: Bool = false,
         isSubscriptionsInOrderCreationCustomersEnabled: Bool = false,
         isPointOfSaleEnabled: Bool = false,
         googleAdsCampaignCreationOnWebView: Bool = false,
         blazeEvergreenCampaigns: Bool = false,
         blazeCampaignObjective: Bool = false,
         revampedShippingLabelCreation: Bool = false) {
        self.isInboxOn = isInboxOn
        self.isShowInboxCTAEnabled = isShowInboxCTAEnabled
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
        self.shippingLabelsOnboardingM1 = shippingLabelsOnboardingM1
        self.isDomainSettingsEnabled = isDomainSettingsEnabled
        self.isSupportRequestEnabled = isSupportRequestEnabled
        self.jetpackSetupWithApplicationPassword = jetpackSetupWithApplicationPassword
        self.betterCustomerSelectionInOrder = betterCustomerSelectionInOrder
        self.productBundlesInOrderForm = productBundlesInOrderForm
        self.isScanToUpdateInventoryEnabled = isScanToUpdateInventoryEnabled
        self.isBackendReceiptsEnabled = isBackendReceiptsEnabled
        self.sideBySideViewForOrderForm = sideBySideViewForOrderForm
        self.isSubscriptionsInOrderCreationCustomersEnabled = isSubscriptionsInOrderCreationCustomersEnabled
        self.isPointOfSaleEnabled = isPointOfSaleEnabled
        self.googleAdsCampaignCreationOnWebView = googleAdsCampaignCreationOnWebView
        self.blazeEvergreenCampaigns = blazeEvergreenCampaigns
        self.blazeCampaignObjective = blazeCampaignObjective
        self.revampedShippingLabelCreation = revampedShippingLabelCreation
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .inbox:
            return isInboxOn
        case .showInboxCTA:
            return isShowInboxCTAEnabled
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
        case .betterCustomerSelectionInOrder:
            return betterCustomerSelectionInOrder
        case .productBundlesInOrderForm:
            return productBundlesInOrderForm
        case .scanToUpdateInventory:
            return isScanToUpdateInventoryEnabled
        case .backendReceipts:
            return isBackendReceiptsEnabled
        case .sideBySideViewForOrderForm:
            return sideBySideViewForOrderForm
        case .subscriptionsInOrderCreationCustomers:
            return isSubscriptionsInOrderCreationCustomersEnabled
        case .pointOfSale:
            return isPointOfSaleEnabled
        case .googleAdsCampaignCreationOnWebView:
            return googleAdsCampaignCreationOnWebView
        case .blazeEvergreenCampaigns:
            return blazeEvergreenCampaigns
        case .blazeCampaignObjective:
            return blazeCampaignObjective
        case .revampedShippingLabelCreation:
            return revampedShippingLabelCreation
        default:
            return false
        }
    }
}
