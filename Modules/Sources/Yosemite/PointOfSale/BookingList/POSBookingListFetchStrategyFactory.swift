import Foundation
import class Networking.AlamofireNetwork
import class Networking.BookingsRemote
import class Networking.OrdersRemote
import class WooFoundationCore.CurrencyFormatter
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite
import protocol Storage.StorageManagerType

public protocol POSBookingListFetchStrategyFactoryProtocol {
    func defaultStrategy(filters: BookingFilters?) -> POSBookingListFetchStrategy
    func searchStrategy(searchTerm: String, filters: BookingFilters?) -> POSBookingListFetchStrategy
    var bookingService: POSBookingServiceProtocol { get }
}

public final class POSBookingListFetchStrategyFactory: POSBookingListFetchStrategyFactoryProtocol {
    private let siteID: Int64
    public let bookingService: POSBookingServiceProtocol

    public init(siteID: Int64,
                credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>,
                appPasswordSupportState: AnyPublisher<Bool, Never>,
                currencyFormatter: CurrencyFormatter,
                storageManager: StorageManagerType,
                siteSettings: [SiteSetting] = []) {
        self.siteID = siteID
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        let bookingsRemote = BookingsRemote(network: network)
        let ordersRemote = OrdersRemote(network: network)
        self.bookingService = POSBookingService(
            siteID: siteID,
            bookingsRemote: bookingsRemote,
            ordersRemote: ordersRemote,
            currencyFormatter: currencyFormatter,
            storageManager: storageManager,
            siteSettings: siteSettings
        )
    }

    public func defaultStrategy(filters: BookingFilters? = nil) -> POSBookingListFetchStrategy {
        POSDefaultBookingListFetchStrategy(bookingService: bookingService, siteID: siteID, filters: filters)
    }

    public func searchStrategy(searchTerm: String, filters: BookingFilters? = nil) -> POSBookingListFetchStrategy {
        POSSearchBookingListFetchStrategy(bookingService: bookingService, siteID: siteID, searchTerm: searchTerm, filters: filters)
    }
}
