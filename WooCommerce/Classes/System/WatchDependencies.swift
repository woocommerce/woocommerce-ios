import Foundation

#if canImport(Networking)
import Networking
#elseif canImport(NetworkingWatchOS)
import NetworkingWatchOS
#endif

#if canImport(WooFoundation)
import class WooFoundation.CurrencySettings
#elseif canImport(WooFoundationWatchOS)
import class WooFoundationWatchOS.CurrencySettings
#endif



/// WatchOS session dependencies.
///
public struct WatchDependencies: Codable, Equatable {

    let storeID: Int64
    let storeName: String
    let currencySettings: CurrencySettings
    let credentials: Credentials
    let applicationPassword: ApplicationPassword?
    let enablesCrashReports: Bool
    let account: Account?

    /// Uses the provided application password
    ///
    public init(storeID: Int64,
                storeName: String,
                currencySettings: CurrencySettings,
                credentials: Credentials,
                applicationPassword: ApplicationPassword?,
                enablesCrashReports: Bool,
                account: Account?) {
        self.storeID = storeID
        self.storeName = storeName
        self.currencySettings = currencySettings
        self.credentials = credentials
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
                enablesCrashReports: Bool,
                account: Account?) {
        self.storeID = storeID
        self.storeName = storeName
        self.currencySettings = currencySettings
        self.credentials = credentials
        self.enablesCrashReports = enablesCrashReports
        self.account = account

        // Always get the stored application password as the application networking classes rely on it.
        // Ideally this should be refactored to live in the credentials object.
        self.applicationPassword = ApplicationPasswordStorage().applicationPassword
    }
}
