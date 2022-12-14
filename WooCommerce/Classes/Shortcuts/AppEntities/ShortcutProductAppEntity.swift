import Foundation
import Yosemite
import AppIntents

@available(iOS 16.0, *)
struct ShortcutProductAppEntity: Identifiable, Hashable, Equatable, AppEntity {
    var id: Int

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Product")
    typealias DefaultQuery = IntentsProductQuery
    static var defaultQuery: IntentsProductQuery = IntentsProductQuery()

    @Property(title: "Title")
    var title: String

    var originalProduct: Product?

    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(
            title: "\(title)"
        )
    }

    init(product: Product) {
        self.id = Int(product.productID)
        self.title = product.name
        self.originalProduct = product
    }
}

@available(iOS 16.0, *)
extension ShortcutProductAppEntity {

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // Equtable conformance
    static func ==(lhs: ShortcutProductAppEntity, rhs: ShortcutProductAppEntity) -> Bool {
        return lhs.id == rhs.id
    }

}

@available(iOS 16.0, *)
struct IntentsProductQuery: EntityPropertyQuery {
    private let stores: StoresManager = ServiceLocator.stores

    func entities(for identifiers: [Int]) async throws -> [ShortcutProductAppEntity] {

        var products: [Product] = []
        for identifier in identifiers {
            products.append(try await product(with: Int64(identifier)))
        }

        return products.compactMap {
            ShortcutProductAppEntity(product: $0)
        }
    }

    private func product(with id: Int64) async throws -> Product {
        try await withCheckedThrowingContinuation { continuation in
            let siteID = stores.sessionManager.defaultStoreID ?? Int64.min
            let action = ProductAction.retrieveProduct(siteID: siteID, productID: Int64(id)) { result in
               continuation.resume(with: result)
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    func suggestedEntities() async throws -> [ShortcutProductAppEntity] {
        await withCheckedContinuation { continuation in
            let action = ProductAction.retrieveStoredProducts { products in
                let shortcutProducts = products.compactMap {
                    ShortcutProductAppEntity(product: $0)
                }
                continuation.resume(returning: shortcutProducts)
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    func entities(matching query: String) async throws -> [ShortcutProductAppEntity] {
        await withCheckedContinuation { continuation in
            let action = ProductAction.retrieveStoredProducts { products in
                let matchingProducts = products.filter {
                    return $0.name.localizedCaseInsensitiveContains(query)
                }


                let shortcutProducts = matchingProducts.compactMap {
                    ShortcutProductAppEntity(product: $0)
                }
                continuation.resume(returning: shortcutProducts)
            }

            Task { @MainActor in
                stores.dispatch(action)
            }
        }
    }

    static var properties = EntityQueryProperties<ShortcutProductAppEntity, NSPredicate> {
        Property(\ShortcutProductAppEntity.$title) {
            EqualToComparator { NSPredicate(format: "title = %@", $0) }
            ContainsComparator { NSPredicate(format: "title CONTAINS %@", $0) }
        }
    }

    static var sortingOptions = SortingOptions {
        SortableBy(\ShortcutProductAppEntity.$title)
    }

    func entities(
        matching comparators: [NSPredicate],
        mode: ComparatorMode,
        sortedBy: [Sort<ShortcutProductAppEntity>],
        limit: Int?
    ) async throws -> [ShortcutProductAppEntity] {
        debugPrint("comparators \(comparators)")
        return []
    }
}
