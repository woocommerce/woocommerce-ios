import Foundation

enum PointOfSaleOrderState: Equatable {
    case idle
    case syncing
    case loaded(PointOfSaleOrderTotals)
    case error(OrderStateError, OrderStateRetryHandler)

    typealias OrderStateRetryHandler = () -> Void

    enum OrderStateError: Equatable {
        case other(String)
        case invalidCoupon(String)
        case missingProducts([MissingProductInfo])

        struct MissingProductInfo: Equatable {
            let productID: Int64
            let variationID: Int64
            let name: String
        }

        static func == (lhs: OrderStateError, rhs: OrderStateError) -> Bool {
            switch (lhs, rhs) {
            case (.other(let lhsError), .other(let rhsError)):
                return lhsError == rhsError
            case (.invalidCoupon(let lhsCoupon), .invalidCoupon(let rhsCoupon)):
                return lhsCoupon == rhsCoupon
            case (.missingProducts(let lhsProducts), .missingProducts(let rhsProducts)):
                return lhsProducts == rhsProducts
            default:
                return false
            }
        }
    }

    static func == (lhs: PointOfSaleOrderState, rhs: PointOfSaleOrderState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
            (.syncing, .syncing),
            (.error, .error):
            return true
        case (.loaded(let lhsTotals), .loaded(let rhsTotals)):
            return lhsTotals == rhsTotals
        default:
            return false
        }
    }

    var isSyncing: Bool {
        switch self {
        case .syncing:
            return true
        default:
            return false
        }
    }

    var isLoaded: Bool {
        switch self {
        case .loaded:
            return true
        default:
            return false
        }
    }

    var isError: Bool {
        switch self {
        case .error:
            return true
        default:
            return false
        }
    }
}
