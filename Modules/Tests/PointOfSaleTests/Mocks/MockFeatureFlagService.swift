@testable import PointOfSale
import Experiments

final class MockFeatureFlagService: POSFeatureFlagProviding {
    var isUpdateOrderOptimisticallyOn: Bool
    var isPointOfSaleEnabled: Bool
    var backgroundProductImageUpload: Bool
    var isFeatureFlagEnabledReturnValue: [FeatureFlag: Bool] = [:]

    init(isUpdateOrderOptimisticallyOn: Bool = false,
         isPointOfSaleEnabled: Bool = false,
         backgroundProductImageUpload: Bool = false) {
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
        self.isPointOfSaleEnabled = isPointOfSaleEnabled
        self.backgroundProductImageUpload = backgroundProductImageUpload
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
        case .pointOfSale:
            return isPointOfSaleEnabled
        case .backgroundProductImageUpload:
            return backgroundProductImageUpload
        case .ciabBookings:
            return false
        case .ciabBookingReschedule:
            return false
        default:
            return false
        }
    }
}
