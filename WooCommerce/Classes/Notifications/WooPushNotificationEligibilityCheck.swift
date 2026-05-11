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

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores) {
        self.featureFlagService = featureFlagService
        self.stores = stores
    }

    @MainActor
    func checkEligibility() async -> Bool {
        let localFlagEnabled = featureFlagService.isFeatureFlagEnabled(.selfDrivenPushToken)

        let remoteFlagEnabled = await withCheckedContinuation { continuation in
            stores.dispatch(FeatureFlagAction.isRemoteFeatureFlagEnabled(
                .selfDrivenPushNotificationsM1,
                defaultValue: false,
                useCache: true,
                completion: { value in
                    continuation.resume(returning: value)
                })
            )
        }

        return localFlagEnabled && remoteFlagEnabled
    }
}
