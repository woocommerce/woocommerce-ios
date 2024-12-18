public enum POSItem: Equatable, Identifiable, Hashable {
    case simpleProduct(POSSimpleProduct)

    public var id: UUID {
        switch self {
        case .simpleProduct(let product):
            return product.id
        }
    }
}

/// POSOrderableItem extends a displayable item with the functions required for using it in an order.
/// This currently includes adding it, and checking whether it's already in an order.
/// This may need to become less specific in future, e.g. we currently convert it to a product input, but
/// other order items might be added as fees or similar. at that point, we will need a different function requirement here.
public protocol POSOrderableItem {
    var id: UUID { get }
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
    func providePointOfSaleItems(pageNumber: Int) async throws -> (items: [POSItem], hasNextPage: Bool)
}

// Default implementation for convenience, so we do not need to pass the first page explicitly
// if no pageNumber is given.
extension PointOfSaleItemServiceProtocol {
    func providePointOfSaleItems(pageNumber: Int = 1) async throws -> [POSItem] {
        try await providePointOfSaleItems(pageNumber: pageNumber)
    }
}
