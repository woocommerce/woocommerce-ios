import Foundation
import class Networking.AlamofireNetwork
import class Networking.OrdersRemote
import class WooFoundationCore.CurrencyFormatter

public protocol PointOfSaleOrderListFetchStrategyFactoryProtocol {
    func defaultStrategy() -> PointOfSaleOrderListFetchStrategy
    func searchStrategy(searchTerm: String) -> PointOfSaleOrderListFetchStrategy
}

public final class PointOfSaleOrderListFetchStrategyFactory: PointOfSaleOrderListFetchStrategyFactoryProtocol {
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

    public func defaultStrategy() -> PointOfSaleOrderListFetchStrategy {
        PointOfSaleDefaultOrderListFetchStrategy(
            orderListService: PointOfSaleOrderListService(
                siteID: siteID,
                ordersRemote: ordersRemote,
                currencyFormatter: currencyFormatter
            )
        )
    }

    public func searchStrategy(searchTerm: String) -> PointOfSaleOrderListFetchStrategy {
        PointOfSaleSearchOrderListFetchStrategy(
            orderListService: PointOfSaleOrderListService(
                siteID: siteID,
                ordersRemote: ordersRemote,
                currencyFormatter: currencyFormatter
            ),
            searchTerm: searchTerm
        )
    }
}
