import Foundation
import struct NetworkingCore.Order

struct OrdersViewState: Equatable {
    var containerState: ItemsContainerState
    var ordersState: OrderListState
}

enum OrderListState: Equatable {
    case loading([Order])
    case loaded([Order], hasMoreItems: Bool)
    case empty
    case error(PointOfSaleErrorState)
    case inlineError([Order], error: PointOfSaleErrorState, context: InlineErrorContext)

    enum InlineErrorContext {
        case refresh
        case pagination
    }

    var orders: [Order] {
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
