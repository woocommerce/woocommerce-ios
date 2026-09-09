import Foundation
import Yosemite
import Experiments

/// Protocol for checking self-driven push notification eligibility.
protocol WooPushNotificationEligibilityChecking {
    @MainActor
    func checkEligibility() async -> Bool
}

/// Helper to check whether self-driven push notifications should be enabled.
final class WooPushNotificationEligibilityCheck: WooPushNotificationEligibilityChecking {
    private let featureFlagService: FeatureFlagService
    private let stores: StoresManager
    private let remoteFeatureFlagService: RemoteFeatureFlagServiceProtocol

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores) {
        self.featureFlagService = featureFlagService
        self.stores = stores
        self.remoteFeatureFlagService = RemoteFeatureFlagService(stores: stores)
    }

    @MainActor
    func checkEligibility() async -> Bool {
        guard stores.isAuthenticated else { return false }

        let defaultM1Value = featureFlagService.isFeatureFlagEnabled(.selfDrivenPushToken)

        return await remoteFeatureFlagService.isEnabled(.selfDrivenPushNotificationsM1, defaultValue: defaultM1Value)
    }
}
