import Foundation
import Yosemite
import AppIntents

@available(iOS 16.0, *)
struct ShortcutOrderAppEntity: Identifiable, Hashable, Equatable, AppEntity {
    var id: Int

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Order")
    typealias DefaultQuery = IntentsOrderQuery
    static var defaultQuery: IntentsOrderQuery = IntentsOrderQuery()

    @Property(title: "Title")
    var title: String

    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(
            title: "\(title)"
        )
    }

    init(id: Int, title: String) {
        self.id = id
        self.title = title
    }
}

@available(iOS 16.0, *)
extension ShortcutOrderAppEntity {

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Equtable conformance
    static func ==(lhs: ShortcutOrderAppEntity, rhs: ShortcutOrderAppEntity) -> Bool {
        return lhs.id == rhs.id
    }

}

@available(iOS 16.0, *)
struct IntentsOrderQuery: EntityPropertyQuery {
    private let stores: StoresManager = ServiceLocator.stores

    func entities(for identifiers: [Int]) async throws -> [ShortcutOrderAppEntity] {

        var orders: [Order] = []
        for identifier in identifiers {
            orders.append(try await order(with: Int64(identifier)))
        }

        return orders.compactMap {
            ShortcutOrderAppEntity(id: Int($0.orderID), title: $0.title)
        }
    }

    private func order(with id: Int64) async throws -> Order {
        try await withCheckedThrowingContinuation { continuation in
            let siteID = stores.sessionManager.defaultStoreID ?? Int64.min
            let action = OrderAction.retrieveOrder(siteID: siteID, orderID: Int64(id)) { (order, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let order = order {
                    continuation.resume(returning: order)
                }
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    func suggestedEntities() async throws -> [ShortcutOrderAppEntity] {
        await withCheckedContinuation { continuation in
            let action = OrderAction.retrieveStoredOrders { orders in
                let shortcutOrders = orders.compactMap {
                    ShortcutOrderAppEntity(id: Int($0.orderID), title: $0.title)
                }
                continuation.resume(returning: shortcutOrders)
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    func entities(matching query: String) async throws -> [ShortcutOrderAppEntity] {
        await withCheckedContinuation { continuation in
            let action = OrderAction.retrieveStoredOrders { orders in
                let matchingOrders = orders.filter {
                    return ($0.number.localizedCaseInsensitiveContains(query) || ($0.billingAddress?.fullName ?? "") .localizedCaseInsensitiveContains(query))
                }


                let shortcutOrders = matchingOrders.compactMap {
                    ShortcutOrderAppEntity(id: Int($0.orderID), title: $0.title)
                }
                continuation.resume(returning: shortcutOrders)
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    static var properties = EntityQueryProperties<ShortcutOrderAppEntity, NSPredicate> {
        Property(\ShortcutOrderAppEntity.$title) {
            EqualToComparator { NSPredicate(format: "title = %@", $0) }
            ContainsComparator { NSPredicate(format: "title CONTAINS %@", $0) }
        }
    }

    static var sortingOptions = SortingOptions {
        SortableBy(\ShortcutOrderAppEntity.$title)
    }

    func entities(
        matching comparators: [NSPredicate],
        mode: ComparatorMode,
        sortedBy: [Sort<ShortcutOrderAppEntity>],
        limit: Int?
    ) async throws -> [ShortcutOrderAppEntity] {
        debugPrint("comparators \(comparators)")
        return []
    }
}

extension Order {
    var title: String {
        OrderListCellViewModel(order: self, status: nil).title
    }
}
