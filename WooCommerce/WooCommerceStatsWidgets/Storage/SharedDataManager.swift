
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
        guard let defaults = UserDefaults(suiteName: "group.org.wordpress"),
              let storeID = defaults.object(forKey: "storeID") as? Int64,
              let authToken = defaults.string(forKey: "authToken"),
              let siteName = defaults.string(forKey: "siteName") else {
            throw SharedDataManagerError.noSharedDataFound
        }

        return SharedData(storeID: storeID, siteName: siteName, authToken: authToken)
    }
}
