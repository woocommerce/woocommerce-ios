@testable import WooCommerce
import Experiments

final class MockFeatureFlagService: FeatureFlagService {
    var isInboxOn: Bool
    var isShowInboxCTAEnabled: Bool
    var isUpdateOrderOptimisticallyOn: Bool
    var shippingLabelsOnboardingM1: Bool
    var isDomainSettingsEnabled: Bool
    var isSupportRequestEnabled: Bool
    var jetpackSetupWithApplicationPassword: Bool
    var betterCustomerSelectionInOrder: Bool
    var productBundlesInOrderForm: Bool
    var isScanToUpdateInventoryEnabled: Bool
    var isBackendReceiptsEnabled: Bool
    var sideBySideViewForOrderForm: Bool
    var isSubscriptionsInOrderCreationCustomersEnabled: Bool
    var isPointOfSaleEnabled: Bool
    var googleAdsCampaignCreationOnWebView: Bool
    var blazeEvergreenCampaigns: Bool
    var blazeCampaignObjective: Bool
    var revampedShippingLabelCreation: Bool
    var viewEditCustomFieldsInProductsAndOrders: Bool
    var favoriteProducts: Bool
    var paymentsOnboardingInPointOfSale: Bool
    var isProductGlobalUniqueIdentifierSupported: Bool
    var isSendReceiptAfterPaymentEnabled: Bool
    var tapToPayEducation: Bool

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
         revampedShippingLabelCreation: Bool = false,
         viewEditCustomFieldsInProductsAndOrders: Bool = false,
         favoriteProducts: Bool = false,
         paymentsOnboardingInPointOfSale: Bool = false,
         isProductGlobalUniqueIdentifierSupported: Bool = false,
         isSendReceiptAfterPaymentEnabled: Bool = false,
         tapToPayEducation: Bool = false) {
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
        self.viewEditCustomFieldsInProductsAndOrders = viewEditCustomFieldsInProductsAndOrders
        self.favoriteProducts = favoriteProducts
        self.paymentsOnboardingInPointOfSale = paymentsOnboardingInPointOfSale
        self.isProductGlobalUniqueIdentifierSupported = isProductGlobalUniqueIdentifierSupported
        self.isSendReceiptAfterPaymentEnabled = isSendReceiptAfterPaymentEnabled
        self.tapToPayEducation = tapToPayEducation
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
        case .viewEditCustomFieldsInProductsAndOrders:
            return viewEditCustomFieldsInProductsAndOrders
        case .favoriteProducts:
            return favoriteProducts
        case .paymentsOnboardingInPointOfSale:
            return paymentsOnboardingInPointOfSale
        case .productGlobalUniqueIdentifierSupport:
            return isProductGlobalUniqueIdentifierSupported
        case .sendReceiptAfterPayment:
            return isSendReceiptAfterPaymentEnabled
        case .tapToPayEducation:
            return tapToPayEducation
        default:
            return false
        }
    }
}
