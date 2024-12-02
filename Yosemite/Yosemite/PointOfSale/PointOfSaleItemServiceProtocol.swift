/// POSDisplayableItem contains only the properties required to show an item in the Point Of Sale.
/// The item may only be visible, not neccesarily something you can add to the cart.
/// This protocol will become less specific in future; e.g. not all items in the POS necessarily have a price.
public protocol POSDisplayableItem: Identifiable {
    var id: UUID { get }
    var name: String { get }
    var formattedPrice: String { get }
    var productImageSource: String? { get }

    func isEqual(to other: any POSDisplayableItem) -> Bool
}

public extension POSDisplayableItem where Self: Equatable {
    func isEqual(to other: any POSDisplayableItem) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}

public extension Sequence where Element == any POSDisplayableItem {
    func isEqual(to other: any Sequence<Element>) -> Bool {
        let lhsArray = Array(self)
        let rhsArray = Array(other)

        guard lhsArray.count == rhsArray.count else { return false }

        return zip(lhsArray, rhsArray).allSatisfy { lhs, rhs in
            lhs.isEqual(to: rhs)
        }
    }
}

/// POSOrderableItem extends a displayable item with the functions required for using it in an order.
/// This currently includes adding it, and checking whether it's already in an order.
/// This may need to become less specific in future, e.g. we currently convert it to a product input, but
/// other order items might be added as fees or similar. at that point, we will need a different function requirement here.
public protocol POSOrderableItem: POSDisplayableItem & PointOfSaleItemOrderItemConvertable {}

public protocol PointOfSaleItemOrderItemConvertable {
    func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput
    func matches(orderItem: OrderItem) -> Bool
}

public protocol PointOfSaleItemServiceProtocol {
    func providePointOfSaleItems(pageNumber: Int) async throws -> [any POSDisplayableItem]
}

// Default implementation for convenience, so we do not need to pass the first page explicitly
// if no pageNumber is given.
extension PointOfSaleItemServiceProtocol {
    func providePointOfSaleItems(pageNumber: Int = 1) async throws -> [any POSDisplayableItem] {
        try await providePointOfSaleItems(pageNumber: pageNumber)
    }
}
