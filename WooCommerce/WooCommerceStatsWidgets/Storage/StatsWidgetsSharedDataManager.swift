
import Foundation

enum StatsWidgetsSharedDataManagerError: Error {
    case noStatsWidgetsSharedDataFound
}

struct StatsWidgetsSharedData {
    let storeID: Int64
    let siteName: String
    let authToken: String
}

struct StatsWidgetsSharedDataManager {
    static func retrieveSharedData() throws -> StatsWidgetsSharedData {
        guard let defaults = UserDefaults(suiteName: StatsWidgetsSharedDataKeys.suiteName),
              let storeID = defaults.object(forKey: StatsWidgetsSharedDataKeys.storeID) as? Int64,
              let authToken = defaults.string(forKey: StatsWidgetsSharedDataKeys.authToken),
              let siteName = defaults.string(forKey: StatsWidgetsSharedDataKeys.siteName) else {
            throw StatsWidgetsSharedDataManagerError.noStatsWidgetsSharedDataFound
        }

        return StatsWidgetsSharedData(storeID: storeID, siteName: siteName, authToken: authToken)
    }
}

private enum StatsWidgetsSharedDataKeys {
    static let suiteName = "group.org.wordpress"
    static let storeID = "storeID"
    static let authToken = "authToken"
    static let siteName = "siteName"
}
