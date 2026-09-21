import Experiments
import Foundation
import Yosemite

protocol AIAssistantEligibilityCheckerProtocol {
    func isEligible(for site: Site?) -> Bool
    func isEligible(for site: Site?, useCache: Bool) async -> Bool
}

struct AIAssistantEligibilityChecker: AIAssistantEligibilityCheckerProtocol {
    private let featureFlagService: FeatureFlagService
    private let remoteFeatureFlagService: RemoteFeatureFlagServiceProtocol

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         stores: StoresManager = ServiceLocator.stores) {
        self.featureFlagService = featureFlagService
        self.remoteFeatureFlagService = RemoteFeatureFlagService(stores: stores)
    }

    func isEligible(for site: Site?) -> Bool {
        localEligibility(for: site)
    }

    func isEligible(for site: Site?, useCache: Bool = true) async -> Bool {
        guard localEligibility(for: site) else {
            return false
        }
        return await remoteFeatureFlagService.isEnabled(.wooAIAssistant, defaultValue: true, useCache: useCache)
    }

    private func localEligibility(for site: Site?) -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.wooAIAssistant) else {
            return false
        }
        guard let site else { return false }
        return site.isWordPressComStore || site.isAIAssistantFeatureActive
    }
}
