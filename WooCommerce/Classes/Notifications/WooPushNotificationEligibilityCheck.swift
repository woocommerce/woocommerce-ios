import Foundation
import Yosemite
import Experiments

/// Helper to check whether self-driven push notifications should be enabled.
final class WooPushNotificationEligibilityCheck {
    private let featureFlagService: FeatureFlagService
    private let stores: StoresManager

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores) {
        self.featureFlagService = featureFlagService
        self.stores = stores
    }

    @MainActor
    func checkM1Eligibility() async -> Bool {
        let defaultM1Value = featureFlagService.isFeatureFlagEnabled(.selfDrivenPushToken)

        return await withCheckedContinuation { continuation in
            stores.dispatch(FeatureFlagAction.isRemoteFeatureFlagEnabled(
                .selfDrivenPushNotificationsM1,
                defaultValue: defaultM1Value,
                useCache: true,
                completion: { value in
                    continuation.resume(returning: value)
                })
            )
        }
    }
}
