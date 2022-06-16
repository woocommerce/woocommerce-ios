
import Foundation

enum SharedDataManagerError: Error {
    case noSharedDataFound
}

struct SharedData {
    let storeID: Int64
    let siteName: String
    let authToken: String
}

struct SharedDataManager {
    static func retrieveSharedData() throws -> SharedData {
        guard let defaults = UserDefaults(suiteName: SharedDataKeys.suiteName),
              let storeID = defaults.object(forKey: SharedDataKeys.storeID) as? Int64,
              let authToken = defaults.string(forKey: SharedDataKeys.authToken),
              let siteName = defaults.string(forKey: SharedDataKeys.siteName) else {
            throw SharedDataManagerError.noSharedDataFound
        }

        return SharedData(storeID: storeID, siteName: siteName, authToken: authToken)
    }
}

private enum SharedDataKeys {
    static let suiteName = "group.org.wordpress"
    static let storeID = "storeID"
    static let authToken = "authToken"
    static let siteName = "siteName"
}
