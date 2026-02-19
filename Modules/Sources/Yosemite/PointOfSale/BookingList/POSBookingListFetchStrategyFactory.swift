import Foundation
import class Networking.AlamofireNetwork
import class Networking.BookingsRemote
import class Networking.OrdersRemote
import class WooFoundationCore.CurrencyFormatter
import protocol Storage.StorageManagerType
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

public protocol POSBookingListFetchStrategyFactoryProtocol {
    func defaultStrategy(filters: BookingFilters?) -> POSBookingListFetchStrategy
    func searchStrategy(searchTerm: String, filters: BookingFilters?) -> POSBookingListFetchStrategy
    var bookingService: POSBookingServiceProtocol { get }
}

public final class POSBookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol {
    private let siteID: Int64
    private let storageManager: StorageManagerType
    private let currencyFormatter: CurrencyFormatter
    private let siteSettings: [SiteSetting]
    private let bookingStoreMethods: BookingStoreMethodsProtocol
    public let bookingService: POSBookingServiceProtocol

    public init(siteID: Int64,
                credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>,
                appPasswordSupportState: AnyPublisher<Bool, Never>,
                storageManager: StorageManagerType,
                currencyFormatter: CurrencyFormatter,
                siteSettings: [SiteSetting] = []) {
        self.siteID = siteID
        self.storageManager = storageManager
        self.currencyFormatter = currencyFormatter
        self.siteSettings = siteSettings
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        let bookingsRemote = BookingsRemote(network: network)
        let ordersRemote = OrdersRemote(network: network)
        self.bookingStoreMethods = BookingStoreMethods(storageManager: storageManager,
                                                       bookingsRemote: bookingsRemote,
                                                       ordersRemote: ordersRemote)
        self.bookingService = POSBookingService(
            siteID: siteID,
            bookingsRemote: bookingsRemote,
            ordersRemote: ordersRemote,
            currencyFormatter: currencyFormatter,
            siteSettings: siteSettings
        )
    }

    public func defaultStrategy(filters: BookingFilters? = nil) -> POSBookingListFetchStrategy {
        POSDefaultBookingListFetchStrategy(bookingStoreMethods: bookingStoreMethods,
                                           storageManager: storageManager,
                                           currencyFormatter: currencyFormatter,
                                           siteSettings: siteSettings,
                                           siteID: siteID,
                                           filters: filters)
    }

    public func searchStrategy(searchTerm: String, filters: BookingFilters? = nil) -> POSBookingListFetchStrategy {
        POSSearchBookingListFetchStrategy(bookingService: bookingService, siteID: siteID, searchTerm: searchTerm, filters: filters)
    }
}
