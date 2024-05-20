import Foundation

#if canImport(Networking)
import enum Networking.Credentials
#elseif canImport(NetworkingWatchOS)
import enum NetworkingWatchOS.Credentials
#endif

#if canImport(WooFoundation)
import class WooFoundation.CurrencySettings
#elseif canImport(WooFoundationWatchOS)
import class WooFoundationWatchOS.CurrencySettings
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
        static let currencySettings = "currency-settings"
    }

    let storeID: Int64
    let storeName: String
    let currencySettings: CurrencySettings
    let credentials: Credentials

    public init(storeID: Int64, storeName: String, currencySettings: CurrencySettings, credentials: Credentials) {
        self.storeID = storeID
        self.storeName = storeName
        self.currencySettings = currencySettings
        self.credentials = credentials
    }

    /// Create Dependencies from a serialized dictionary.
    public init?(dictionary: [String: Any]) {

        guard let storeDic = dictionary[Keys.store] as? [String: Any] else {
            return nil
        }

        let storeID = storeDic[Keys.id] as? Int64
        let storeName = storeDic[Keys.name] as? String

        // Read currency settings as a base64-string
        let currencySettings: CurrencySettings = {
            // If we could not find any setting, use a default one.
            guard let base64Settings = storeDic[Keys.currencySettings] as? String,
                  let currencyData = Data(base64Encoded: base64Settings),
                  let settings = try? JSONDecoder().decode(CurrencySettings.self, from: currencyData) else {
                return CurrencySettings()
            }
            return settings
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

        guard let storeID, let storeName, let credentials else {
            return nil
        }

        self.init(storeID: storeID, storeName: storeName, currencySettings: currencySettings, credentials: credentials)
    }

    /// Dictionary to be transferred between sessions.
    ///
    public func toDictionary() -> [String: Any] {
        // Send currency settings as a base64-string because a Data type can't be transferred to the watch.
        let currencySettingJsonAsBase64 = (try? JSONEncoder().encode(currencySettings))?.base64EncodedString() ?? ""
        return [
            Keys.credentials: [
                Keys.type: credentials.rawType,
                Keys.username: credentials.username,
                Keys.secret: credentials.secret,
                Keys.address: credentials.siteAddress
            ],
            Keys.store: [
                Keys.id: storeID,
                Keys.name: storeName,
                Keys.currencySettings: currencySettingJsonAsBase64
            ]
        ]
    }
}
