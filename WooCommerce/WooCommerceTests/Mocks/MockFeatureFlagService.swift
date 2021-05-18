@testable import WooCommerce

struct MockFeatureFlagService: FeatureFlagService {
    private let isShippingLabelsM2M3On: Bool
    private let isShippingLabelsM4On: Bool

    init(isShippingLabelsM2M3On: Bool = false,
         isShippingLabelsM4On: Bool = false) {
        self.isShippingLabelsM2M3On = isShippingLabelsM2M3On
        self.isShippingLabelsM4On = isShippingLabelsM4On
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .shippingLabelsM2M3:
            return isShippingLabelsM2M3On
        case .shippingLabelsM4:
            return isShippingLabelsM4On
        default:
            return false
        }
    }
}
