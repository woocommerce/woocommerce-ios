import Foundation
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderRefund

struct OrdersViewState: Equatable {
    var containerState: ItemsContainerState
    var ordersState: OrderListState
}

enum OrderListState: Equatable {
    case loading([POSOrder])
    case loaded([POSOrder], hasMoreItems: Bool)
    case empty
    case error(PointOfSaleErrorState)
    case inlineError([POSOrder], error: PointOfSaleErrorState, context: InlineErrorContext)

    enum InlineErrorContext {
        case refresh
        case pagination
    }

    var orders: [POSOrder] {
        switch self {
        case .loading(let orders):
            return orders
        case .loaded(let orders, _):
            return orders
        case .empty:
            return []
        case .error:
            return []
        case .inlineError(let orders, _, _):
            return orders
        }
    }
}
