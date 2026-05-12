import Experiments
import Foundation
import Yosemite

protocol AIAssistantEligibilityCheckerProtocol {
    func isEligible(for site: Site?) -> Bool
    func isEligible(for site: Site?, useCache: Bool) async -> Bool
}

struct AIAssistantEligibilityChecker: AIAssistantEligibilityCheckerProtocol {
    private let featureFlagService: FeatureFlagService
    private let stores: StoresManager

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores) {
        self.featureFlagService = featureFlagService
        self.stores = stores
    }

    func isEligible(for site: Site?) -> Bool {
        localEligibility(for: site)
    }

    func isEligible(for site: Site?, useCache: Bool = true) async -> Bool {
        guard localEligibility(for: site) else {
            return false
        }
        return await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let action = FeatureFlagAction.isRemoteFeatureFlagEnabled(.wooAIAssistant,
                                                                      defaultValue: true,
                                                                      useCache: useCache) { isEnabled in
                continuation.resume(returning: isEnabled)
            }
            stores.dispatch(action)
        }
    }

    private func localEligibility(for site: Site?) -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.wooAIAssistant) else {
            return false
        }
        guard let site else { return false }
        return site.isWordPressComStore || site.isAIAssistantFeatureActive
    }
}
