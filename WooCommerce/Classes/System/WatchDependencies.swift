import Foundation

#if canImport(Networking)
import enum Networking.Credentials
#endif

#if canImport(NetworkingWatchOS)
import enum NetworkingWatchOS.Credentials
#endif

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
        static let name = "name"
    }

    let storeID: Int64
    let storeName: String
    let credentials: Credentials

    public init(storeID: Int64, storeName: String, credentials: Credentials) {
        self.storeID = storeID
        self.storeName = storeName
        self.credentials = credentials
    }

    /// Create Dependencies from a serialized dictionary.
    public init?(dictionary: [String: Any]) {

        guard let storeDic = dictionary[Keys.store] as? [String: Any] else {
            return nil
        }

        let storeID = storeDic[Keys.id] as? Int64
        let storeName = storeDic[Keys.name] as? String

        let credentials: Credentials? = {
            guard let credentialsDic = dictionary[Keys.credentials] as? [String: String],
                  let type = credentialsDic[Keys.type],
                  let username = credentialsDic[Keys.username],
                  let secret = credentialsDic[Keys.secret],
                  let siteAddress = credentialsDic[Keys.address] else {
                return nil
            }

            switch type {
            case "AuthenticationType.wpcom":
                return .wpcom(username: username, authToken: secret, siteAddress: siteAddress)
            case "AuthenticationType.wporg":
                return .wporg(username: username, password: secret, siteAddress: siteAddress)
            case "AuthenticationType.applicationPassword":
                return .applicationPassword(username: username, password: secret, siteAddress: siteAddress)
            default:
                return nil
            }
        }()

        guard let storeID, let storeName, let credentials else {
            return nil
        }

        self.init(storeID: storeID, storeName: storeName, credentials: credentials)
    }

    /// Dictionary to be transferred between sessions.
    ///
    public func toDictionary() -> [String: Any] {
        [
            Keys.credentials: [
                Keys.type: credentials.rawType,
                Keys.username: credentials.username,
                Keys.secret: credentials.secret,
                Keys.address: credentials.siteAddress
            ],
            Keys.store: [
                Keys.id: storeID,
                Keys.name: storeName
            ]
        ]
    }
}
