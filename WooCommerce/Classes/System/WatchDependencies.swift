import Foundation

#if canImport(Networking)
import enum Networking.Credentials
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
    }

    let storeID: Int64?
    let credentials: Credentials?

    public init(storeID: Int64?, credentials: Credentials?) {
        self.storeID = storeID
        self.credentials = credentials
    }

    /// Create Dependencies from a serialized dictionary.
    public init(dictionary: [String: Any]) {
        let storeID: Int64? = {
            guard let storeDic = dictionary[Keys.store] as? [String: Int64] else {
                return nil
            }

            return storeDic[Keys.id]
        }()

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

        self.init(storeID: storeID, credentials: credentials)
    }

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
