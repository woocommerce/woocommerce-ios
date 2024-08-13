import Foundation
import UIKit

struct HelpAndSupportViewModel {
    private let isAuthenticated: Bool
    private let isZendeskEnabled: Bool
    private let isMacCatalyst: Bool

    init(isAuthenticated: Bool, isZendeskEnabled: Bool, isMacCatalyst: Bool) {
        self.isAuthenticated = isAuthenticated
        self.isZendeskEnabled = isZendeskEnabled
        self.isMacCatalyst = isMacCatalyst
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
}
