@testable import WooCommerce
import Experiments

struct MockFeatureFlagService: FeatureFlagService {
    private let isJetpackConnectionPackageSupportOn: Bool
    private let isHubMenuOn: Bool
    private let isInboxOn: Bool
    private let isSplitViewInOrdersTabOn: Bool
    private let isUpdateOrderOptimisticallyOn: Bool

    init(isJetpackConnectionPackageSupportOn: Bool = false,
         isHubMenuOn: Bool = false,
         isInboxOn: Bool = false,
         isSplitViewInOrdersTabOn: Bool = false,
         isUpdateOrderOptimisticallyOn: Bool = false) {
        self.isJetpackConnectionPackageSupportOn = isJetpackConnectionPackageSupportOn
        self.isHubMenuOn = isHubMenuOn
        self.isInboxOn = isInboxOn
        self.isSplitViewInOrdersTabOn = isSplitViewInOrdersTabOn
        self.isUpdateOrderOptimisticallyOn = isUpdateOrderOptimisticallyOn
    }

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .jetpackConnectionPackageSupport:
            return isJetpackConnectionPackageSupportOn
        case .hubMenu:
            return isHubMenuOn
        case .inbox:
            return isInboxOn
        case .splitViewInOrdersTab:
            return isSplitViewInOrdersTabOn
        case .updateOrderOptimistically:
            return isUpdateOrderOptimisticallyOn
        default:
            return false
        }
    }
}
