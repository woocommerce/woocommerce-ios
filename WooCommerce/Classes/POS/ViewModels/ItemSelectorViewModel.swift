import Combine
import SwiftUI
import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider

final class ItemSelectorViewModel: ObservableObject {
    enum ItemSelectorState {
        case loading
        case loaded
        case error
    }

    @Published private(set) var items: [POSItem] = []
    @Published private(set) var state: ItemSelectorState = .loading
    var isSyncingItems: Bool {
        state == .loading
    }

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
