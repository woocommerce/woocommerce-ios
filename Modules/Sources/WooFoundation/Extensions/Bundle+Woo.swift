import Foundation

extension Bundle {
    public var buildNumber: String {
        guard let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String else {
            return "unknown"
        }

        return buildNumber
    }

    public var marketingVersion: String {
        guard let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return "unknown"
        }

        return marketingVersion
    }
}
