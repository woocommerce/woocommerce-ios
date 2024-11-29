public protocol PointOfSaleItemDisplayable: Identifiable {
    var id: UUID { get }
    var name: String { get }
    var formattedPrice: String { get }
    var productImageSource: String? { get }

    func isEqual(to other: any PointOfSaleItemDisplayable) -> Bool
}

public extension PointOfSaleItemDisplayable where Self: Equatable {
    func isEqual(to other: any PointOfSaleItemDisplayable) -> Bool {
        guard let other = other as? Self else { return false }
        return self == other
    }
}

public extension Sequence where Element == any PointOfSaleItemDisplayable {
    func isEqual(to other: any Sequence<Element>) -> Bool {
        let lhsArray = Array(self)
        let rhsArray = Array(other)

        guard lhsArray.count == rhsArray.count else { return false }

        return zip(lhsArray, rhsArray).allSatisfy { lhs, rhs in
            lhs.isEqual(to: rhs)
        }
    }
}

public protocol PointOfSaleItemOrderItemConvertable {
    func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput
    func matches(orderItem: OrderItem) -> Bool
}

public typealias POSDisplayableItem = PointOfSaleItemDisplayable
public typealias POSOrderableItem = POSDisplayableItem & PointOfSaleItemOrderItemConvertable

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
