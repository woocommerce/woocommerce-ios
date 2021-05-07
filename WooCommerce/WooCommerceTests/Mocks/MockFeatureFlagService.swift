@testable import WooCommerce

struct MockFeatureFlagService: FeatureFlagService {
    private let isShippingLabelsRelease2On: Bool
    private let isShippingLabelsRelease3On: Bool

    init(isShippingLabelsRelease2On: Bool = false,
         isShippingLabelsRelease3On: Bool = false) {
        self.isShippingLabelsRelease2On = isShippingLabelsRelease2On
        self.isShippingLabelsRelease3On = isShippingLabelsRelease3On
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .shippingLabelsRelease2:
            return isShippingLabelsRelease2On
        case .shippingLabelsRelease3:
            return isShippingLabelsRelease3On
        default:
            return false
        }
    }
}
