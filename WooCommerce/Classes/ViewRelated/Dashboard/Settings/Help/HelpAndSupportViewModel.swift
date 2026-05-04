import Foundation
import UIKit

struct HelpAndSupportViewModel {
    private let isAuthenticated: Bool
    private let isZendeskEnabled: Bool
    private let isMacCatalyst: Bool
    private let hasLoginSiteURL: Bool
    private let developerFFPanelEnabled: Bool
    private let isAIChatEnabled: Bool

    init(isAuthenticated: Bool,
         isZendeskEnabled: Bool,
         isMacCatalyst: Bool,
         hasLoginSiteURL: Bool = false,
         developerFFPanelEnabled: Bool = false,
         isAIChatEnabled: Bool = false) {
        self.isAuthenticated = isAuthenticated
        self.isZendeskEnabled = isZendeskEnabled
        self.isMacCatalyst = isMacCatalyst
        self.developerFFPanelEnabled = developerFFPanelEnabled
        self.hasLoginSiteURL = hasLoginSiteURL
        self.isAIChatEnabled = isAIChatEnabled
    }

    func getRows() -> [HelpAndSupportRow] {
        if isMacCatalyst {
            return [.helpCenter]
        }

        guard isZendeskEnabled else {
            return [.helpCenter]
        }

        var rows: [HelpAndSupportRow] = [.helpCenter, .contactSupport, .contactEmail, .applicationLog]
        if isAuthenticated {
            rows.append(.systemStatusReport)
        }
        if !isAuthenticated && hasLoginSiteURL {
            rows.append(.siteCompatibility)
        }
        if isAIChatEnabled {
            rows.append(.aiSupportChat)
        }
        if isAuthenticated && isAIChatEnabled {
            rows.append(.chatHistory)
        }
        return rows
    }

    func getDeveloperRows() -> [HelpAndSupportRow] {
        guard developerFFPanelEnabled else {
            return []
        }
        return [.featureFlags]
    }
}
