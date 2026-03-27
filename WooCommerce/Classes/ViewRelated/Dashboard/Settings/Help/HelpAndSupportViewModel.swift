import Foundation
import UIKit
import Experiments

struct HelpAndSupportViewModel {
    private let isAuthenticated: Bool
    private let isZendeskEnabled: Bool
    private let isMacCatalyst: Bool
    private let featureFlagService: FeatureFlagService

    init(isAuthenticated: Bool,
         isZendeskEnabled: Bool,
         isMacCatalyst: Bool,
         featureFlagService: FeatureFlagService = DefaultFeatureFlagService()) {
        self.isAuthenticated = isAuthenticated
        self.isZendeskEnabled = isZendeskEnabled
        self.isMacCatalyst = isMacCatalyst
        self.featureFlagService = featureFlagService
    }

    func getRows() -> [HelpAndSupportRow] {
        if isMacCatalyst {
            return [.helpCenter]
        }

        guard isZendeskEnabled else {
            return [.helpCenter]
        }

        var rows: [HelpAndSupportRow] = []

        if isAuthenticated && featureFlagService.isFeatureFlagEnabled(.aiHelp) {
            rows.append(.aiHelp)
        }

        rows.append(contentsOf: [.helpCenter, .contactSupport, .contactEmail, .applicationLog])
        if isAuthenticated {
            rows.append(.systemStatusReport)
        }
        return rows
    }
}
