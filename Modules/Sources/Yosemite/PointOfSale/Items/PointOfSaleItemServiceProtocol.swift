import Foundation
import struct Networking.PagedItems

public enum POSItem: Equatable, Identifiable, Hashable {
    case simpleProduct(POSSimpleProduct)
    case variableParentProduct(POSVariableParentProduct)
    case variation(POSVariation)
    case searchResultVariation(POSVariation, parentProduct: POSVariableParentProduct)
    case coupon(POSCoupon)

    public var id: POSItemIdentifier {
        switch self {
        case .simpleProduct(let product):
            return product.id
        case .variableParentProduct(let parentProduct):
            return parentProduct.id
        case .variation(let variation):
            return variation.id
        case .searchResultVariation(let variation, _):
            return variation.id
        case .coupon(let coupon):
            return coupon.id
        }
    }
}

/// POSOrderableItem extends a displayable item with the functions required for using it in an order.
/// This currently includes adding it, and checking whether it's already in an order.
/// This may need to become less specific in future, e.g. we currently convert it to a product input, but
/// other order items might be added as fees or similar. at that point, we will need a different function requirement here.
public protocol POSOrderableItem {
    var id: POSItemIdentifier { get }
    var name: String { get }
    var productImageSource: String? { get }
    var formattedPrice: String { get }

    func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput
    func matches(orderItem: OrderItem) -> Bool
    func isEqual(to other: POSOrderableItem) -> Bool
}

public extension POSOrderableItem where Self: Equatable {
    func isEqual(to other: POSOrderableItem) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}

public extension Sequence where Element == POSOrderableItem {
    func isEqual(to other: any Sequence<Element>) -> Bool {
        let lhsArray = Array(self)
        let rhsArray = Array(other)

        guard lhsArray.count == rhsArray.count else { return false }

        return zip(lhsArray, rhsArray).allSatisfy { lhs, rhs in
            lhs.isEqual(to: rhs)
        }
    }
}

public protocol PointOfSaleItemServiceProtocol {
    func providePointOfSaleItems(pageNumber: Int,
                                 fetchStrategy: PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<POSItem>
    func providePointOfSaleVariationItems(for parentProduct: POSVariableParentProduct,
                                          pageNumber: Int,
                                          fetchStrategy: PointOfSalePurchasableItemFetchStrategy) async throws -> PagedItems<POSItem>
}
