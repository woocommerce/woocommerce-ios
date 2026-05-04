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
        let baseEligibility = site.isWordPressComStore || site.isAIAssistantFeatureActive || site.isJetpackConnected
        guard baseEligibility else {
            return false
        }
        return canMintJWT(with: credentialsProvider())
    }

    private func canMintJWT(with credentials: Credentials?) -> Bool {
        switch credentials {
        case .wpcom, .applicationPassword:
            return true
        case .wporg, .none:
            return false
        }
    }
}
