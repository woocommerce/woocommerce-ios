@testable import PointOfSale
import Experiments

final class MockFeatureFlagService: POSFeatureFlagProviding {
    var isInboxOn: Bool
    var isShowInboxCTAEnabled: Bool
    var isUpdateOrderOptimisticallyOn: Bool
    var isSupportRequestEnabled: Bool
    var betterCustomerSelectionInOrder: Bool
    var productBundlesInOrderForm: Bool
    var isScanToUpdateInventoryEnabled: Bool
    var isPointOfSaleEnabled: Bool
    var blazeCampaignObjective: Bool
    var revampedShippingLabelCreation: Bool
    var hideSitesInStorePicker: Bool
    var backgroundProductImageUpload: Bool
    var isProductImageOptimizedHandlingEnabled: Bool
    var isFeatureFlagEnabledReturnValue: [FeatureFlag: Bool] = [:]

    init(isInboxOn: Bool = false,
         isShowInboxCTAEnabled: Bool = false,
         isUpdateOrderOptimisticallyOn: Bool = false,
         isSupportRequestEnabled: Bool = false,
         betterCustomerSelectionInOrder: Bool = false,
         productBundlesInOrderForm: Bool = false,
         isScanToUpdateInventoryEnabled: Bool = false,
         isPointOfSaleEnabled: Bool = false,
         blazeCampaignObjective: Bool = false,
         revampedShippingLabelCreation: Bool = false,
         hideSitesInStorePicker: Bool = false,
         backgroundProductImageUpload: Bool = false,
         isProductImageOptimizedHandlingEnabled: Bool = false) {
        self.isInboxOn = isInboxOn
        self.isShowInboxCTAEnabled = isShowInboxCTAEnabled
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
        self.isSupportRequestEnabled = isSupportRequestEnabled
        self.betterCustomerSelectionInOrder = betterCustomerSelectionInOrder
        self.productBundlesInOrderForm = productBundlesInOrderForm
        self.isScanToUpdateInventoryEnabled = isScanToUpdateInventoryEnabled
        self.isPointOfSaleEnabled = isPointOfSaleEnabled
        self.blazeCampaignObjective = blazeCampaignObjective
        self.revampedShippingLabelCreation = revampedShippingLabelCreation
        self.hideSitesInStorePicker = hideSitesInStorePicker
        self.backgroundProductImageUpload = backgroundProductImageUpload
        self.isProductImageOptimizedHandlingEnabled = isProductImageOptimizedHandlingEnabled
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
        case .supportRequests:
            return isSupportRequestEnabled
        case .betterCustomerSelectionInOrder:
            return betterCustomerSelectionInOrder
        case .productBundlesInOrderForm:
            return productBundlesInOrderForm
        case .scanToUpdateInventory:
            return isScanToUpdateInventoryEnabled
        case .pointOfSale:
            return isPointOfSaleEnabled
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
            return false
        case .ciabBookingReschedule:
            return false
        default:
            return false
        }
    }
}
