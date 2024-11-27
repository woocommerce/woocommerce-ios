public protocol PointOfSaleItemDisplayable: Identifiable, Equatable {
    var name: String { get }
    var formattedPrice: String { get }
    var productImageSource: String? { get }
}

public protocol PointOfSaleItemOrderItemConvertable {
    func toOrderItem() -> OrderItem
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
