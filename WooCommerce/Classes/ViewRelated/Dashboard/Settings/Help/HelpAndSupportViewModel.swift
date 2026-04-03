import Foundation
import UIKit

struct HelpAndSupportViewModel {
    private let isAuthenticated: Bool
    private let isZendeskEnabled: Bool
    private let isMacCatalyst: Bool
    private let hasLoginSiteURL: Bool

    init(isAuthenticated: Bool, isZendeskEnabled: Bool, isMacCatalyst: Bool, hasLoginSiteURL: Bool = false) {
        self.isAuthenticated = isAuthenticated
        self.isZendeskEnabled = isZendeskEnabled
        self.isMacCatalyst = isMacCatalyst
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
        if !isAuthenticated && hasLoginSiteURL {
            rows.append(.siteCompatibility)
        }
        return rows
    }
}
