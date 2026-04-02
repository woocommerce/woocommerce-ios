import Foundation
import UIKit

struct HelpAndSupportViewModel {
    private let isAuthenticated: Bool
    private let isZendeskEnabled: Bool
    private let isMacCatalyst: Bool
    private let developerFFPanelEnabled: Bool

    init(isAuthenticated: Bool,
         isZendeskEnabled: Bool,
         isMacCatalyst: Bool,
         developerFFPanelEnabled: Bool = false) {
        self.isAuthenticated = isAuthenticated
        self.isZendeskEnabled = isZendeskEnabled
        self.isMacCatalyst = isMacCatalyst
        self.developerFFPanelEnabled = developerFFPanelEnabled
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
        return rows
    }

    func getDeveloperRows() -> [HelpAndSupportRow] {
        guard developerFFPanelEnabled else {
            return []
        }
        return [.featureFlags]
    }
}
