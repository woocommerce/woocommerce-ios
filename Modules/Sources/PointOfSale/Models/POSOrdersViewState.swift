import Foundation
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderRefund

enum POSOrderListState: Equatable {
    case loading([POSOrder])
    case loaded([POSOrder], hasMoreItems: Bool)
    case inlineError([POSOrder], error: PointOfSaleErrorState, context: InlineErrorContext)
    case error(PointOfSaleErrorState)
    case empty

    enum InlineErrorContext {
        case refresh
        case pagination
    }

    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    var isEmpty: Bool {
        switch self {
        case .loaded:
            return false
        case .loading(let orders):
            return orders.isEmpty
        default:
            return true
        }
    }

    var orders: [POSOrder] {
        switch self {
        case .loading(let orders),
             .loaded(let orders, _),
             .inlineError(let orders, _, _):
            return orders
        case .error, .empty:
            return []
        }
    }

    func updatingOrders(with updatedOrders: [POSOrder]) -> POSOrderListState {
        switch self {
        case .loaded(_, let hasMoreItems):
            return .loaded(updatedOrders, hasMoreItems: hasMoreItems)
        case .loading:
            return .loading(updatedOrders)
        case .inlineError(_, let error, let context):
            return .inlineError(updatedOrders, error: error, context: context)
        case .empty, .error:
            return self
        }
    }
}
