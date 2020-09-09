import Foundation

extension Bundle {
    var buildNumber: String {
        guard let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return "unknown"
        }

        return buildNumber
    }

    var marketingVersion: String {
        guard let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "unknown"
        }

        return marketingVersion
    }
}
