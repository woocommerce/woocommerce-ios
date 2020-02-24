import Foundation
import XLPagerTabStrip

extension IndicatorInfo {

    private static let accessibilityIdentifierKey = "accessibility-identifier"

    init(title: String, accessibilityIdentifier: String) {
        self.init(title: title)
        self.userInfo = [
            IndicatorInfo.accessibilityIdentifierKey: accessibilityIdentifier
        ]
    }

    var accessibilityIdentifier: String {
        guard let userInfo = self.userInfo as? [String: String] else {
            return ""
        }

        return userInfo[IndicatorInfo.accessibilityIdentifierKey] ?? ""
    }
}
