@testable import PointOfSale
import Experiments

final class MockFeatureFlagService: POSFeatureFlagProviding {
    var isInboxOn: Bool
    var isShowInboxCTAEnabled: Bool
    var isUpdateOrderOptimisticallyOn: Bool
    var shippingLabelsOnboardingM1: Bool
    var isSupportRequestEnabled: Bool
    var jetpackSetupWithApplicationPassword: Bool
    var betterCustomerSelectionInOrder: Bool
    var productBundlesInOrderForm: Bool
    var isScanToUpdateInventoryEnabled: Bool
    var isSubscriptionsInOrderCreationCustomersEnabled: Bool
    var isSubscriptionsInOrderCreationUIEnabled: Bool
    var isPointOfSaleEnabled: Bool
    var googleAdsCampaignCreationOnWebView: Bool
    var blazeEvergreenCampaigns: Bool
    var blazeCampaignObjective: Bool
    var revampedShippingLabelCreation: Bool
    var hideSitesInStorePicker: Bool
    var backgroundProductImageUpload: Bool
    var isProductImageOptimizedHandlingEnabled: Bool
    var isFeatureFlagEnabledReturnValue: [FeatureFlag: Bool] = [:]
    var isCIABBookingsEnabled: Bool
    var isPointOfSaleRefundsi1Enabled: Bool

    init(isInboxOn: Bool = false,
         isShowInboxCTAEnabled: Bool = false,
         isUpdateOrderOptimisticallyOn: Bool = false,
         shippingLabelsOnboardingM1: Bool = false,
         isSupportRequestEnabled: Bool = false,
         jetpackSetupWithApplicationPassword: Bool = false,
         betterCustomerSelectionInOrder: Bool = false,
         productBundlesInOrderForm: Bool = false,
         isScanToUpdateInventoryEnabled: Bool = false,
         isSubscriptionsInOrderCreationCustomersEnabled: Bool = false,
         isSubscriptionsInOrderCreationUIEnabled: Bool = false,
         isPointOfSaleEnabled: Bool = false,
         googleAdsCampaignCreationOnWebView: Bool = false,
         blazeEvergreenCampaigns: Bool = false,
         blazeCampaignObjective: Bool = false,
         revampedShippingLabelCreation: Bool = false,
         hideSitesInStorePicker: Bool = false,
         backgroundProductImageUpload: Bool = false,
         isProductImageOptimizedHandlingEnabled: Bool = false,
         isCIABBookingsEnabled: Bool = false,
         isPointOfSaleRefundsi1Enabled: Bool = false) {
        self.isInboxOn = isInboxOn
        self.isShowInboxCTAEnabled = isShowInboxCTAEnabled
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
        self.shippingLabelsOnboardingM1 = shippingLabelsOnboardingM1
        self.isSupportRequestEnabled = isSupportRequestEnabled
        self.jetpackSetupWithApplicationPassword = jetpackSetupWithApplicationPassword
        self.betterCustomerSelectionInOrder = betterCustomerSelectionInOrder
        self.productBundlesInOrderForm = productBundlesInOrderForm
        self.isScanToUpdateInventoryEnabled = isScanToUpdateInventoryEnabled
        self.isSubscriptionsInOrderCreationCustomersEnabled = isSubscriptionsInOrderCreationCustomersEnabled
        self.isSubscriptionsInOrderCreationUIEnabled = isSubscriptionsInOrderCreationUIEnabled
        self.isPointOfSaleEnabled = isPointOfSaleEnabled
        self.googleAdsCampaignCreationOnWebView = googleAdsCampaignCreationOnWebView
        self.blazeEvergreenCampaigns = blazeEvergreenCampaigns
        self.blazeCampaignObjective = blazeCampaignObjective
        self.revampedShippingLabelCreation = revampedShippingLabelCreation
        self.hideSitesInStorePicker = hideSitesInStorePicker
        self.backgroundProductImageUpload = backgroundProductImageUpload
        self.isProductImageOptimizedHandlingEnabled = isProductImageOptimizedHandlingEnabled
        self.isCIABBookingsEnabled = isCIABBookingsEnabled
        self.isPointOfSaleRefundsi1Enabled = isPointOfSaleRefundsi1Enabled
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        // Checks if we a custom return value is set for a specific flag.
        if let customValue = isFeatureFlagEnabledReturnValue[featureFlag] {
            return customValue
        }

        // Otherwise uses the default implementation.
        switch featureFlag {
        case .inbox:
            return isInboxOn
        case .showInboxCTA:
            return isShowInboxCTAEnabled
        case .updateOrderOptimistically:
            return isUpdateOrderOptimisticallyOn
        case .shippingLabelsOnboardingM1:
            return shippingLabelsOnboardingM1
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
        case .subscriptionsInOrderCreationCustomers:
            return isSubscriptionsInOrderCreationCustomersEnabled
        case .subscriptionsInOrderCreationUI:
            return isSubscriptionsInOrderCreationUIEnabled
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
        case .hideSitesInStorePicker:
            return hideSitesInStorePicker
        case .backgroundProductImageUpload:
            return backgroundProductImageUpload
        case .productImageOptimizedHandling:
            return isProductImageOptimizedHandlingEnabled
        case .ciabBookings:
            return isCIABBookingsEnabled
        case .pointOfSaleRefundsi1:
            return isPointOfSaleRefundsi1Enabled
        default:
            return false
        }
    }
}
