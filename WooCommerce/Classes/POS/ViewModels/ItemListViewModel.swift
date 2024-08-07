import Combine
import SwiftUI
import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider

final class ItemListViewModel: ItemListViewModelProtocol {

    @Published private(set) var items: [POSItem] = []
    @Published private(set) var state: ItemListState = .loading
    @Published private(set) var shouldShowHeaderBanner: Bool

    var isEmptyOrError: Bool {
        switch state {
        case .empty, .error:
            return true
        default:
            return false
        }
    }

    private let itemProvider: POSItemProvider
    private let selectedItemSubject: PassthroughSubject<POSItem, Never> = .init()

    let selectedItemPublisher: AnyPublisher<POSItem, Never>

    var itemsPublisher: Published<[POSItem]>.Publisher { $items }
    var statePublisher: Published<ItemListViewModel.ItemListState>.Publisher { $state }

    init(itemProvider: POSItemProvider) {
        self.itemProvider = itemProvider
        selectedItemPublisher = selectedItemSubject.eraseToAnyPublisher()

        // The banner is shown as long as it hasn't already been dismissed once:
        let isBannerDismissed = UserDefaults.standard.bool(forKey: BannerState.isSimpleProductsOnlyBannerDismissedKey)
        shouldShowHeaderBanner = !isBannerDismissed
        observeBannerDismissal()
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
        UserDefaults.standard.set(true, forKey: BannerState.isSimpleProductsOnlyBannerDismissedKey)
    }

    private func observeBannerDismissal() {
        let bannerDismissPublisher = UserDefaults.standard.publisher(for: BannerState.isSimpleProductsOnlyBannerDismissedKey)

        Publishers.CombineLatest(statePublisher, bannerDismissPublisher)
            .map { state, bannerDismissed in
                return state.isLoaded && !bannerDismissed
            }
            .removeDuplicates()
            .assign(to: &$shouldShowHeaderBanner)
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

    struct BannerState {
        static let isSimpleProductsOnlyBannerDismissedKey = "isSimpleProductsOnlyBannerDismissed"
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

// Emits values whenever UserDefaults changes, and it maps the notification to the specific key's value.
// This is needed for simpler keypath handling, as allows us to use the string key directly
extension UserDefaults {
    func publisher(for key: String) -> AnyPublisher<Bool, Never> {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification, object: self)
            .map { _ in
                return self.bool(forKey: key)
            }
            .eraseToAnyPublisher()
    }
}
