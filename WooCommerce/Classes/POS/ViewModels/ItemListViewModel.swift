import Combine
import SwiftUI
import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider

final class ItemListViewModel: ObservableObject {

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
                let itemListEmpty = EmptyModel(title: Constants.emptyProductsTitle,
                                                  subtitle: Constants.emptyProductsSubtitle,
                                                  hint: Constants.emptyProductsHint,
                                                  buttonText: Constants.emptyProductsButtonTitle)
                state = .empty(itemListEmpty)
            } else {
                state = .loaded(items)
            }
        } catch {
            DDLogError("Error on load while fetching product data: \(error)")
            let itemListError = ErrorModel(title: Constants.failedToLoadTitle,
                                      subtitle: Constants.failedToLoadSubtitle,
                                      buttonText: Constants.failedToLoadButtonTitle)
            state = .error(itemListError)
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
                let itemListEmpty = EmptyModel(title: Constants.emptyProductsTitle,
                                                  subtitle: Constants.emptyProductsSubtitle,
                                                  hint: Constants.emptyProductsHint,
                                                  buttonText: Constants.emptyProductsButtonTitle)
                state = .empty(itemListEmpty)
            } else {
                // Only clears in-memory items if the `do` block continues, otherwise we keep them in memory.
                items.removeAll()
                items = newItems
                state = .loaded(items)
            }
        } catch {
            DDLogError("Error on reload while updating product data: \(error)")
            let itemListError = ErrorModel(title: Constants.failedToLoadTitle,
                                      subtitle: Constants.failedToLoadSubtitle,
                                      buttonText: Constants.failedToLoadButtonTitle)
            state = .error(itemListError)
        }
    }
}

extension ItemListViewModel {
    enum ItemListState: Equatable {
        case empty(EmptyModel)
        // TODO:
        // Differentiate between loading on entering POS mode and reloading, as the
        // screens will be different:
        // https://github.com/woocommerce/woocommerce-ios/issues/13286
        case loading
        case loaded([POSItem])
        case error(ErrorModel)

        // Equatable conformance for testing:
        static func == (lhs: ItemListViewModel.ItemListState, rhs: ItemListViewModel.ItemListState) -> Bool {
            switch (lhs, rhs) {
            case (.empty(let lhsItems), .empty(let rhsItems)):
                return lhsItems == rhsItems
            case (.loading, .loading):
                return true
            case (.loaded(let lhsItems), .loaded(let rhsItems)):
                return lhsItems.map { $0.itemID } == rhsItems.map { $0.itemID }
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    struct ErrorModel: Equatable {
        let title: String
        let subtitle: String
        let buttonText: String
    }

    struct EmptyModel: Equatable {
        // TODO:
        // Differentiate between empty with no products vs empty with no eligible products
        // https://github.com/woocommerce/woocommerce-ios/issues/12815
        // https://github.com/woocommerce/woocommerce-ios/issues/12816
        let title: String
        let subtitle: String
        let hint: String
        let buttonText: String
    }
}

private extension ItemListViewModel {
    enum Constants {
        static let emptyProductsTitle = NSLocalizedString(
            "",
            value: "No products",
            comment: ""
        )
        static let emptyProductsSubtitle = NSLocalizedString(
            "",
            value: "Your store doesn't have any products",
            comment: ""
        )
        static let emptyProductsHint = NSLocalizedString(
            "",
            value: "POS currently only supports simple products",
            comment: ""
        )
        static let emptyProductsButtonTitle = NSLocalizedString(
            "",
            value: "Create a simple product",
            comment: ""
        )
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
