import Yosemite
import Experiments

struct SelfDrivenPushEligibility {
    let stores: StoresManager
    let featureFlagService: FeatureFlagService

    func isEnabled() -> Bool {
        if stores.isAuthenticatedWithoutWPCom {
            return featureFlagService.isFeatureFlagEnabled(.selfDrivenPushTokenAppPasswords)
        }
        return featureFlagService.isFeatureFlagEnabled(.selfDrivenPushTokenWPCom)
    }
}
