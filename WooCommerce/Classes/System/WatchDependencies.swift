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
public struct WatchDependencies: Codable, Equatable {

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
}
