import Foundation
import class Networking.AlamofireNetwork
import class Networking.OrdersRemote

public protocol PointOfSaleOrderListFetchStrategyFactoryProtocol {
    func defaultStrategy() -> PointOfSaleOrderListFetchStrategy
}

public final class PointOfSaleOrderListFetchStrategyFactory: PointOfSaleOrderListFetchStrategyFactoryProtocol {
    private let siteID: Int64
    private let ordersRemote: OrdersRemote

    public init(siteID: Int64,
                credentials: Credentials?) {
        self.siteID = siteID
        let network = AlamofireNetwork(credentials: credentials)
        self.ordersRemote = OrdersRemote(network: network)
    }

    public func defaultStrategy() -> PointOfSaleOrderListFetchStrategy {
        PointOfSaleDefaultOrderListFetchStrategy(orderListService: PointOfSaleOrderListService(siteID: siteID,
                                                                                               ordersRemote: ordersRemote))
    }
}
