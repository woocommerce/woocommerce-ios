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

// MARK: - Missing Product Helpers
extension Array where Element == PointOfSaleOrderState.OrderStateError.MissingProductInfo {
    /// Extracts product and variation IDs from missing product info
    /// Returns a tuple of (productIDs, variationIDs) containing only non-zero IDs
    func extractProductAndVariationIDs() -> (productIDs: Set<Int64>, variationIDs: Set<Int64>) {
        var productIDs = Set<Int64>()
        var variationIDs = Set<Int64>()

        for missingProduct in self {
            // If variationID is non-zero, it's a variation
            if missingProduct.variationID != 0 {
                variationIDs.insert(missingProduct.variationID)
            }
            // If productID is non-zero (and variationID is zero), it's a simple product
            else if missingProduct.productID != 0 {
                productIDs.insert(missingProduct.productID)
            }
            // Skip items with both IDs as 0 (generic errors where we can't identify the product)
        }

        return (productIDs, variationIDs)
    }
}
