import Foundation
import struct Yosemite.POSOrder
import struct Yosemite.POSOrderItem
import struct Yosemite.POSOrderRefund

enum OrderListState: Equatable {
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
}
