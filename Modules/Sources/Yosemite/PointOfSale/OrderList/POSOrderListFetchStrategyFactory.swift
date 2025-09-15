import Foundation
import class Networking.AlamofireNetwork
import class Networking.OrdersRemote
import class WooFoundationCore.CurrencyFormatter

public protocol POSOrderListFetchStrategyFactoryProtocol {
    func defaultStrategy() -> POSOrderListFetchStrategy
    func searchStrategy(searchTerm: String) -> POSOrderListFetchStrategy
}

public final class POSOrderListFetchStrategyFactory: POSOrderListFetchStrategyFactoryProtocol {
    private let siteID: Int64
    private let ordersRemote: OrdersRemote
    private let currencyFormatter: CurrencyFormatter

    public init(siteID: Int64,
                credentials: Credentials?,
                currencyFormatter: CurrencyFormatter) {
        self.siteID = siteID
        let network = AlamofireNetwork(credentials: credentials)
        self.ordersRemote = OrdersRemote(network: network)
        self.currencyFormatter = currencyFormatter
    }

    public func defaultStrategy() -> POSOrderListFetchStrategy {
        POSDefaultOrderListFetchStrategy(
            orderListService: POSOrderListService(
                siteID: siteID,
                ordersRemote: ordersRemote,
                currencyFormatter: currencyFormatter
            )
        )
    }

    public func searchStrategy(searchTerm: String) -> POSOrderListFetchStrategy {
        POSSearchOrderListFetchStrategy(
            orderListService: POSOrderListService(
                siteID: siteID,
                ordersRemote: ordersRemote,
                currencyFormatter: currencyFormatter
            ),
            searchTerm: searchTerm
        )
    }
}
