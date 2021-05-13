@testable import WooCommerce

struct MockFeatureFlagService: FeatureFlagService {
    private let isShippingLabelsRelease2On: Bool
    private let isShippingLabelsM4On: Bool

    init(isShippingLabelsRelease2On: Bool = false,
         isShippingLabelsM4On: Bool = false) {
        self.isShippingLabelsRelease2On = isShippingLabelsRelease2On
        self.isShippingLabelsM4On = isShippingLabelsM4On
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .shippingLabelsRelease2:
            return isShippingLabelsRelease2On
        case .shippingLabelsM4:
            return isShippingLabelsM4On
        default:
            return false
        }
    }
}
