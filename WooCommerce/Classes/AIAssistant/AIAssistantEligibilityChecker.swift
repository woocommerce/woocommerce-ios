import Experiments
import Foundation
import enum NetworkingCore.Credentials
import struct Yosemite.Site

protocol AIAssistantEligibilityCheckerProtocol {
    func isEligible(for site: Site?) -> Bool
}

struct AIAssistantEligibilityChecker: AIAssistantEligibilityCheckerProtocol {
    private let featureFlagService: FeatureFlagService
    private let credentialsProvider: () -> Credentials?

    init(featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         credentialsProvider: @escaping () -> Credentials? = { ServiceLocator.stores.sessionManager.defaultCredentials }) {
        self.featureFlagService = featureFlagService
        self.credentialsProvider = credentialsProvider
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
}
