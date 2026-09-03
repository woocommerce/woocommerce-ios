@testable import WooCommerce
import Experiments
import protocol PointOfSale.POSFeatureFlagProviding

final class MockFeatureFlagService: FeatureFlagService, POSFeatureFlagProviding {
    var isUpdateOrderOptimisticallyOn: Bool
    var isSupportRequestEnabled: Bool
    var betterCustomerSelectionInOrder: Bool
    var productBundlesInOrderForm: Bool
    var isScanToUpdateInventoryEnabled: Bool
    var isPointOfSaleEnabled: Bool
    var backgroundProductImageUpload: Bool
    var isProductImageOptimizedHandlingEnabled: Bool
    var isFeatureFlagEnabledReturnValue: [FeatureFlag: Bool] = [:]
    var selfDrivenPushToken: Bool
    var smarterNotifications: Bool

    init(isUpdateOrderOptimisticallyOn: Bool = false,
         isSupportRequestEnabled: Bool = false,
         betterCustomerSelectionInOrder: Bool = false,
         productBundlesInOrderForm: Bool = false,
         isScanToUpdateInventoryEnabled: Bool = false,
         isPointOfSaleEnabled: Bool = false,
         backgroundProductImageUpload: Bool = false,
         isProductImageOptimizedHandlingEnabled: Bool = false,
         selfDrivenPushToken: Bool = false,
         smarterNotifications: Bool = false) {
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
        self.isSupportRequestEnabled = isSupportRequestEnabled
        self.betterCustomerSelectionInOrder = betterCustomerSelectionInOrder
        self.productBundlesInOrderForm = productBundlesInOrderForm
        self.isScanToUpdateInventoryEnabled = isScanToUpdateInventoryEnabled
        self.isPointOfSaleEnabled = isPointOfSaleEnabled
        self.backgroundProductImageUpload = backgroundProductImageUpload
        self.isProductImageOptimizedHandlingEnabled = isProductImageOptimizedHandlingEnabled
        self.selfDrivenPushToken = selfDrivenPushToken
        self.smarterNotifications = smarterNotifications
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        // Checks if we a custom return value is set for a specific flag.
        if let customValue = isFeatureFlagEnabledReturnValue[featureFlag] {
            return customValue
        }

        // Otherwise uses the default implementation.
        switch featureFlag {
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
        case .backgroundProductImageUpload:
            return backgroundProductImageUpload
        case .productImageOptimizedHandling:
            return isProductImageOptimizedHandlingEnabled
        case .ciabBookings:
            return false
        case .ciabBookingReschedule:
            return false
        case .selfDrivenPushToken:
            return selfDrivenPushToken
        case .smarterNotifications:
            return smarterNotifications
        default:
            return false
        }
    }
}
