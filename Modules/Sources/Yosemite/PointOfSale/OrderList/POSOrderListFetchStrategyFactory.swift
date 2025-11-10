import Foundation
import class Networking.AlamofireNetwork
import class Networking.OrdersRemote
import class WooFoundationCore.CurrencyFormatter
import struct Combine.AnyPublisher
import struct NetworkingCore.JetpackSite

public protocol POSOrderListFetchStrategyFactoryProtocol {
    func defaultStrategy() -> POSOrderListFetchStrategy
    func searchStrategy(searchTerm: String) -> POSOrderListFetchStrategy
}

public final class POSOrderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryProtocol {
    private let siteID: Int64
    private let ordersRemote: OrdersRemote
    private let currencyFormatter: CurrencyFormatter
    private let analytics: POSOrderListFetchAnalyticsTracking

    public init(siteID: Int64,
                credentials: Credentials?,
                selectedSite: AnyPublisher<JetpackSite?, Never>,
                appPasswordSupportState: AnyPublisher<Bool, Never>,
                currencyFormatter: CurrencyFormatter,
                analytics: POSOrderListFetchAnalyticsTracking) {
        self.siteID = siteID
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: selectedSite,
                                       appPasswordSupportState: appPasswordSupportState)
        self.ordersRemote = OrdersRemote(network: network)
        self.currencyFormatter = currencyFormatter
        self.analytics = analytics
    }

    public func defaultStrategy() -> POSOrderListFetchStrategy {
        POSDefaultOrderListFetchStrategy(
            orderListService: POSOrderListService(
                siteID: siteID,
                ordersRemote: ordersRemote,
                currencyFormatter: currencyFormatter
            ),
            analytics: analytics
        )
    }

    public func searchStrategy(searchTerm: String) -> POSOrderListFetchStrategy {
        POSSearchOrderListFetchStrategy(
            orderListService: POSOrderListService(
                siteID: siteID,
                ordersRemote: ordersRemote,
                currencyFormatter: currencyFormatter
            ),
            searchTerm: searchTerm,
            analytics: analytics
        )
    }
}
