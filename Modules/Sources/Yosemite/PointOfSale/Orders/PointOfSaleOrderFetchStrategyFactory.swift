import Foundation
import class Networking.AlamofireNetwork
import class Networking.OrdersRemote

public protocol PointOfSaleOrderFetchStrategyFactoryProtocol {
    func defaultStrategy() -> PointOfSaleOrderFetchStrategy
}

public final class PointOfSaleOrderFetchStrategyFactory: PointOfSaleOrderFetchStrategyFactoryProtocol {
    private let siteID: Int64
    private let ordersRemote: OrdersRemote

    public init(siteID: Int64,
                credentials: Credentials?) {
        self.siteID = siteID
        let network = AlamofireNetwork(credentials: credentials)
        self.ordersRemote = OrdersRemote(network: network)
    }

    public func defaultStrategy() -> PointOfSaleOrderFetchStrategy {
        PointOfSaleDefaultOrderFetchStrategy(orderService: PointOfSaleOrderService(siteID: siteID, ordersRemote: ordersRemote))
    }
}

public final class PointOfSaleFixedOrderFetchStrategyFactory: PointOfSaleOrderFetchStrategyFactoryProtocol {
    private let fixedStrategy: PointOfSaleOrderFetchStrategy

    public init(fixedStrategy: PointOfSaleOrderFetchStrategy) {
        self.fixedStrategy = fixedStrategy
    }

    public func defaultStrategy() -> PointOfSaleOrderFetchStrategy {
        fixedStrategy
    }
}
