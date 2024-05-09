import Foundation

/// WatchOS session dependencies.
///
public struct WatchDependencies {

    // Dictionary Keys
    private enum Keys {
        static let credentials = "credentials"
        static let store = "store"
        static let type = "type"
        static let username = "username"
        static let secret = "secret"
        static let address = "address"
        static let id = "id"
    }

    let storeID: Int64?
    let credentials: Credentials?

    /// Dictionary to be transferred between sessions.
    ///
    public func toDictionary() -> [String: Any] {
        guard let credentials, let storeID else {
            return [Keys.credentials: [:], Keys.store: [:]]
        }

        return [
            Keys.credentials: [
                Keys.type: credentials.rawType,
                Keys.username: credentials.username,
                Keys.secret: credentials.secret,
                Keys.address: credentials.siteAddress
            ],
            Keys.store: [
                Keys.id: storeID
            ]
        ]
    }
}
