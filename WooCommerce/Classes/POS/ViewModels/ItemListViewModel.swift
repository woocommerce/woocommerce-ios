import Combine
import SwiftUI
import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider

final class ItemListViewModel: ObservableObject {

    @Published private(set) var items: [POSItem] = []
    @Published private(set) var state: ItemListState = .loading
    @Published private(set) var isHeaderBannerDismissed: Bool = false

    var isEmptyOrError: Bool {
        switch state {
        case .empty, .error:
            return true
        default:
            return false
        }
    }

    var shouldShowHeaderBanner: Bool {
        // The banner it's only shown when:
        // - Loading the item list
        // - Hasn't been already been previously dismissed
        !isHeaderBannerDismissed && state.isLoaded
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
        await populatePointOfSaleItems()
    }

    func dismissBanner() {
        isHeaderBannerDismissed = true
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

        var isLoaded: Bool {
            switch self {
            case .loaded:
                return true
            default:
                return false
            }
        }

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
            "pos.itemList.emptyProductsTitle",
            value: "No products",
            comment: "Text appearing on the item list screen when there are no products to load."
        )
        static let emptyProductsSubtitle = NSLocalizedString(
            "pos.itemList.emptyProductsSubtitle",
            value: "Your store doesn't have any products",
            comment: "Text appearing as subtitle on the item list screen when there are no products to load."
        )
        static let emptyProductsHint = NSLocalizedString(
            "pos.itemList.emptyProductsHint",
            value: "POS currently only supports simple products",
            comment: "Text appearing on the item list screen as hint when there are no products to load."
        )
        static let emptyProductsButtonTitle = NSLocalizedString(
            "pos.itemList.emptyProductsButtonTitle",
            value: "Create a simple product",
            comment: "Text for the button appearing on the item list screen when there are no products to load."
        )
        static let failedToLoadTitle = NSLocalizedString(
            "pos.itemList.failedToLoadTitle",
            value: "Error loading products",
            comment: "Text appearing on the item list screen when there's an error loading products."
        )
        static let failedToLoadSubtitle = NSLocalizedString(
            "pos.itemList.failedToLoadSubtitle",
            value: "Give it another go?",
            comment: "Text appearing on the item list screen as subtitle when there's an error loading products."
        )
        static let failedToLoadButtonTitle = NSLocalizedString(
            "pos.itemList.failedToLoadButtonTitle",
            value: "Retry",
            comment: "Text for the button appearing on the item list screen when there's an error loading products."
        )
    }
}
