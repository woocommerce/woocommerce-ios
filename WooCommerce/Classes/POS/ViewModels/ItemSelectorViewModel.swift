import Combine
import SwiftUI
import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider

final class ItemSelectorViewModel: ObservableObject {
    enum ItemSelectorState {
        // TODO:
        // Differentiate between loading on entering POS mode and reloading, as the
        // screens will be different:
        // https://github.com/woocommerce/woocommerce-ios/issues/13286
        case loading
        // TODO:
        // Differentiate between loaded with products vs with no products vs with no eligible products
        // https://github.com/woocommerce/woocommerce-ios/issues/12815
        // https://github.com/woocommerce/woocommerce-ios/issues/12816
        case loaded
        // TODO:
        // https://github.com/woocommerce/woocommerce-ios/issues/12846
        case error
    }

    @Published private(set) var items: [POSItem] = []
    @Published private(set) var state: ItemSelectorState = .loading

    private let itemProvider: POSItemProvider
    private let selectedItemSubject: PassthroughSubject<POSItem, Never> = .init()

    let selectedItemPublisher: AnyPublisher<POSItem, Never>

    init(itemProvider: POSItemProvider) {
        self.itemProvider = itemProvider
        selectedItemPublisher = selectedItemSubject.eraseToAnyPublisher()
    }

    func select(_ item: POSItem) {
        selectedItemSubject.send(item)
    }

    @MainActor
    func populatePointOfSaleItems() async {
        do {
            items = try await itemProvider.providePointOfSaleItems()
            state = .loaded
        } catch {
            DDLogError("Error on load while fetching product data: \(error)")
            state = .error
        }
    }

    @MainActor
    func reload() async {
        do {
            let newItems = try await itemProvider.providePointOfSaleItems()
            // Only clears in-memory items if the `do` block continues, otherwise we keep them in memory.
            items.removeAll()
            items = newItems
            state = .loaded
        } catch {
            DDLogError("Error on reload while updating product data: \(error)")
            state = .error
        }
    }
}
