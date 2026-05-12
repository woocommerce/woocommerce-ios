import Experiments
import Foundation
import Yosemite
import enum NetworkingCore.Credentials

protocol AIAssistantEligibilityCheckerProtocol {
    func isEligible(for site: Site?) -> Bool
    func isEligible(for site: Site?, useCache: Bool) async -> Bool
}

struct AIAssistantEligibilityChecker: AIAssistantEligibilityCheckerProtocol {
    private let featureFlagService: FeatureFlagService
    private let credentialsProvider: () -> Credentials?
    private let stores: StoresManager

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         credentialsProvider: @escaping () -> Credentials? = { ServiceLocator.stores.sessionManager.defaultCredentials },
         stores: StoresManager = ServiceLocator.stores) {
        self.featureFlagService = featureFlagService
        self.credentialsProvider = credentialsProvider
        self.stores = stores
    }

    func isEligible(for site: Site?) -> Bool {
        guard featureFlagService.isFeatureFlagEnabled(.wooAIAssistant), let site else {
            return false
        }
        guard case .wpcom = credentialsProvider() else {
            return false
        }
        return site.isWordPressComStore || site.isAIAssistantFeatureActive
    }

    func isEligible(for site: Site?, useCache: Bool = true) async -> Bool {
        guard isEligible(for: site) else {
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
}
