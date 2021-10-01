import Experiments

final class MockFeatureFlagService: FeatureFlagService {
    var isPushNotificationsForAllStoresOn: Bool = false

    func isFeatureFlagEnabled(_ featureFlag: FeatureFlag) -> Bool {
        switch featureFlag {
        case .pushNotificationsForAllStores:
            return isPushNotificationsForAllStoresOn
        default:
            return false
        }
    }
}
