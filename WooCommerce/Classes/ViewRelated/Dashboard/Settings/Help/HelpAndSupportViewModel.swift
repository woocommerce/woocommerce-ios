import Foundation
import UIKit

struct HelpAndSupportViewModel {
    private let isAuthenticated: Bool
    private let isZendeskEnabled: Bool
    private let isMacCatalyst: Bool
    private let hasLoginSiteURL: Bool
    private let developerFFPanelEnabled: Bool

    init(isAuthenticated: Bool,
         isZendeskEnabled: Bool,
         isMacCatalyst: Bool,
         hasLoginSiteURL: Bool = false,
         developerFFPanelEnabled: Bool = false) {
        self.isAuthenticated = isAuthenticated
        self.isZendeskEnabled = isZendeskEnabled
        self.isMacCatalyst = isMacCatalyst
        self.developerFFPanelEnabled = developerFFPanelEnabled
        self.hasLoginSiteURL = hasLoginSiteURL
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
        // Unlike the store-scoped system status report, this one needs no store and no network. On the login
        // screen it is the only device information a ticket would carry, which is where it is most useful.
        rows.append(.mobileStatusReport)
        if !isAuthenticated && hasLoginSiteURL {
            rows.append(.siteCompatibility)
        }
        if isAuthenticated {
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
