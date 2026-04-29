import Foundation

#if canImport(Networking)
import Networking
#elseif canImport(NetworkingCore)
import NetworkingCore
#endif

import class WooFoundationCore.CurrencySettings



/// WatchOS session dependencies.
///
public struct WatchDependencies: Codable, Equatable {

    let storeID: Int64
    let storeName: String
    let currencySettings: CurrencySettings
    let credentials: Credentials
    let supportsJetpackVisitorStats: Bool
    let applicationPassword: ApplicationPassword?
    let enablesCrashReports: Bool
    let account: Account?

    /// Uses the provided application password
    ///
    public init(storeID: Int64,
                storeName: String,
                currencySettings: CurrencySettings,
                credentials: Credentials,
                supportsJetpackVisitorStats: Bool,
                applicationPassword: ApplicationPassword?,
                enablesCrashReports: Bool,
                account: Account?) {
        self.storeID = storeID
        self.storeName = storeName
        self.currencySettings = currencySettings
        self.credentials = credentials
        self.supportsJetpackVisitorStats = supportsJetpackVisitorStats
        self.applicationPassword = applicationPassword
        self.enablesCrashReports = enablesCrashReports
        self.account = account

    }

    /// Uses the stored application password
    ///
    public init(storeID: Int64,
                storeName: String,
                currencySettings: CurrencySettings,
                credentials: Credentials,
                supportsJetpackVisitorStats: Bool,
                enablesCrashReports: Bool,
                account: Account?) {
        self.storeID = storeID
        self.storeName = storeName
        self.currencySettings = currencySettings
        self.credentials = credentials
        self.supportsJetpackVisitorStats = supportsJetpackVisitorStats
        self.enablesCrashReports = enablesCrashReports
        self.account = account

        // Always get the stored application password as the application networking classes rely on it.
        // Ideally this should be refactored to live in the credentials object.
        self.applicationPassword = ApplicationPasswordStorage().applicationPassword
    }

    enum CodingKeys: String, CodingKey {
        case storeID
        case storeName
        case currencySettings
        case credentials
        case supportsJetpackVisitorStats
        case applicationPassword
        case enablesCrashReports
        case account
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let storeID = try container.decode(Int64.self, forKey: .storeID)
        let storeName = try container.decode(String.self, forKey: .storeName)
        let currencySettings = try container.decode(CurrencySettings.self, forKey: .currencySettings)
        let credentials = try container.decode(Credentials.self, forKey: .credentials)
        let supportsJetpackVisitorStats = try container.decodeIfPresent(Bool.self, forKey: .supportsJetpackVisitorStats) ?? false
        let applicationPassword = try container.decodeIfPresent(ApplicationPassword.self, forKey: .applicationPassword)
        let enablesCrashReports = try container.decode(Bool.self, forKey: .enablesCrashReports)
        let account = try container.decodeIfPresent(Account.self, forKey: .account)

        self.init(storeID: storeID,
                  storeName: storeName,
                  currencySettings: currencySettings,
                  credentials: credentials,
                  supportsJetpackVisitorStats: supportsJetpackVisitorStats,
                  applicationPassword: applicationPassword,
                  enablesCrashReports: enablesCrashReports,
                  account: account)
    }

}
