import Foundation
import UIKit

struct HelpAndSupportViewModel {
    private let isAuthenticated: Bool
    private let isZendeskEnabled: Bool
    private let isMacCatalyst: Bool
    private let hasLoginSiteURL: Bool
    private let developerFFPanelEnabled: Bool
    private let isAISupportChatEnabled: Bool

    init(isAuthenticated: Bool,
         isZendeskEnabled: Bool,
         isMacCatalyst: Bool,
         hasLoginSiteURL: Bool = false,
         developerFFPanelEnabled: Bool = false,
         isAISupportChatEnabled: Bool = false) {
        self.isAuthenticated = isAuthenticated
        self.isZendeskEnabled = isZendeskEnabled
        self.isMacCatalyst = isMacCatalyst
        self.developerFFPanelEnabled = developerFFPanelEnabled
        self.hasLoginSiteURL = hasLoginSiteURL
        self.isAISupportChatEnabled = isAISupportChatEnabled
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
        if isAuthenticated && isAISupportChatEnabled {
            rows.append(.aiSupportChat)
        }
        if !isAuthenticated && hasLoginSiteURL {
            rows.append(.siteCompatibility)
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
