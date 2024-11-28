import protocol Yosemite.POSDisplayableItem
import typealias Yosemite.POSOrderableItem

enum ItemListState: Equatable {
    case empty
    case initialLoading
    case loading(_ currentItems: [any POSDisplayableItem])
    case loaded(_ items: [any POSDisplayableItem])
    case error(PointOfSaleErrorState)

    var isLoadingAfterInitialLoad: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }

    static func == (lhs: ItemListState, rhs: ItemListState) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty),
            (.initialLoading, .initialLoading):
            return true
        case (.loading(let lhsItems), .loading(let rhsItems)),
            (.loaded(let lhsItems), .loaded(let rhsItems)):
            return itemsAreEqual(lhsItems, rhsItems)
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError == rhsError
        default:
            return false
        }
    }

    // Internal helper for comparing items
    @available(*, message: "")
    private static func itemsAreEqual(
        _ lhs: [any POSDisplayableItem],
        _ rhs: [any POSDisplayableItem]
    ) -> Bool {
        let lhsWrapped = lhs.map { AnyEquatablePOSDisplayableItem($0) }
        let rhsWrapped = rhs.map { AnyEquatablePOSDisplayableItem($0) }
        return lhsWrapped == rhsWrapped
    }
}


import Foundation
import struct Yosemite.OrderItem
import struct Yosemite.OrderSyncProductInput
struct AnyEquatablePOSDisplayableItem: POSDisplayableItem, Equatable, Identifiable {
    private let _isEqual: (Any) -> Bool

    init<T: POSDisplayableItem & Equatable>(_ item: T) {
        self.id = item.id
        self.name = item.name
        self.formattedPrice = item.formattedPrice
        self.productImageSource = item.productImageSource
        self._isEqual = { ($0 as? T) == item }
    }

    var id: UUID
    var name: String
    var formattedPrice: String
    var productImageSource: String?

    static func == (lhs: AnyEquatablePOSDisplayableItem, rhs: AnyEquatablePOSDisplayableItem) -> Bool {
        return lhs._isEqual(rhs)
    }
}

struct AnyEquatablePOSOrderableItem: POSOrderableItem, Equatable, Identifiable {
    private let wrappedItem: any POSOrderableItem

    private let _isEqual: (Any) -> Bool

    init<T: POSOrderableItem & Identifiable>(_ item: T) {
        wrappedItem = item
        self._isEqual = { ($0 as? T) == item }
    }

    var id: UUID { wrappedItem.id }
    var name: String { wrappedItem.name }
    var formattedPrice: String { wrappedItem.formattedPrice }
    var productImageSource: String? { wrappedItem.productImageSource }

    func toOrderSyncProductInput(quantity: Decimal) -> OrderSyncProductInput {
        wrappedItem.toOrderSyncProductInput(quantity: quantity)
    }
    
    func matches(orderItem: OrderItem) -> Bool {
        wrappedItem.matches(orderItem: orderItem)
    }

    static func == (lhs: AnyEquatablePOSOrderableItem, rhs: AnyEquatablePOSOrderableItem) -> Bool {
        return lhs._isEqual(rhs)
    }
}
