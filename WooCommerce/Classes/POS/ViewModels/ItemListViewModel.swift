import Combine
import SwiftUI
import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider

struct ItemListError {
    let title: String
    let subtitle: String
    let error: Error
    let buttonText: String
}

struct ItemListEmpty {
    // TODO:
    // Differentiate between empty with no products vs empty with no eligible products
    // https://github.com/woocommerce/woocommerce-ios/issues/12815
    // https://github.com/woocommerce/woocommerce-ios/issues/12816
    let title: String
    let subtitle: String
    let hint: String
    let buttonText: String
}

final class ItemListViewModel: ObservableObject {
    enum ItemListState {
        case empty(ItemListEmpty)
        // TODO:
        // Differentiate between loading on entering POS mode and reloading, as the
        // screens will be different:
        // https://github.com/woocommerce/woocommerce-ios/issues/13286
        case loading
        case loaded([POSItem])
        case error(ItemListError)
    }

    @Published private(set) var items: [POSItem] = []
    @Published private(set) var state: ItemListState = .loading

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
            state = .loading
            items = try await itemProvider.providePointOfSaleItems()
            if items.count == 0 {
                let itemListEmpty = ItemListEmpty(title: "No products",
                                                  subtitle: "Your store doesn't have any products",
                                                  hint: "POS currently only supports simple products", 
                                                  buttonText: "Create a simple product")
                state = .empty(itemListEmpty)
            } else {
                state = .loaded(items)
            }
        } catch {
            DDLogError("Error on load while fetching product data: \(error)")
            let error = ItemListError(title: Constants.failedToLoadTitle,
                                      subtitle: Constants.failedToLoadSubtitle,
                                      error: error,
                                      buttonText: "Retry")
            state = .error(error)
        }
    }

    @MainActor
    func reload() async {
        do {
            // TODO:
            // Resolve duplication with populatePointOfSaleItems()
            state = .loading
            let newItems = try await itemProvider.providePointOfSaleItems()
            if newItems.count == 0 {
                let itemListEmpty = ItemListEmpty(title: "No products",
                                                  subtitle: "Your store doesn't have any products",
                                                  hint: "POS currently only supports simple products",
                                                  buttonText: "Create a simple product")
                state = .empty(itemListEmpty)
            } else {
                // Only clears in-memory items if the `do` block continues, otherwise we keep them in memory.
                items.removeAll()
                items = newItems
                state = .loaded(items)
            }
        } catch {
            DDLogError("Error on reload while updating product data: \(error)")
            let error = ItemListError(title: Constants.failedToLoadTitle,
                                      subtitle: Constants.failedToLoadSubtitle,
                                      error: error,
                                      buttonText: "Retry")
            state = .error(error)
        }
    }
}

private extension ItemListViewModel {
    enum Constants {
        static let failedToLoadTitle = NSLocalizedString(
            "",
            value: "Error loading products",
            comment: ""
        )
        static let failedToLoadSubtitle = NSLocalizedString(
            "",
            value: "Give it another go?",
            comment: ""
        )
        static let failedToLoadButtonTitle = NSLocalizedString(
            "",
            value: "Retry",
            comment: ""
        )
    }
}
