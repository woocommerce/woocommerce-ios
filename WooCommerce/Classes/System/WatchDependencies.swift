import Foundation

#if canImport(Networking)
import enum Networking.Credentials
import struct Networking.ApplicationPasswordStorage
import struct Networking.ApplicationPassword
#elseif canImport(NetworkingWatchOS)
import enum NetworkingWatchOS.Credentials
import struct NetworkingWatchOS.ApplicationPasswordStorage
import struct NetworkingWatchOS.ApplicationPassword
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

    /// Uses the provided application password
    ///
    public init(storeID: Int64,
                storeName: String,
                currencySettings: CurrencySettings,
                credentials: Credentials,
                applicationPassword: ApplicationPassword?,
                enablesCrashReports: Bool) {
        self.storeID = storeID
        self.storeName = storeName
        self.currencySettings = currencySettings
        self.credentials = credentials
        self.applicationPassword = applicationPassword
        self.enablesCrashReports = enablesCrashReports

    }

    /// Uses the stored application password
    ///
    public init(storeID: Int64, storeName: String, currencySettings: CurrencySettings, credentials: Credentials, enablesCrashReports: Bool) {
        self.storeID = storeID
        self.storeName = storeName
        self.currencySettings = currencySettings
        self.credentials = credentials
        self.enablesCrashReports = enablesCrashReports

        // Always get the stored application password as the application networking classes rely on it.
        // Ideally this should be refactored to live in the credentials object.
        self.applicationPassword = ApplicationPasswordStorage().applicationPassword

    }
}
