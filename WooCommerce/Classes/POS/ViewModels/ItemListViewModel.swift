import Combine
import SwiftUI
import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider

final class ItemListViewModel: ItemListViewModelProtocol {

    @Published private(set) var items: [POSItem] = []
    @Published private(set) var state: ItemListState = .loading
    @Published private(set) var isHeaderBannerDismissed: Bool = false
    @Published var showSimpleProductsModal: Bool = false

    private var currentPage: Int = 0
    private var nextPage: Int = 1

    var shouldShowHeaderBanner: Bool {
        // The banner it's shown as long as it hasn't already been dismissed once:
        if UserDefaults.standard.bool(forKey: BannerState.isSimpleProductsOnlyBannerDismissedKey) == true {
            return false
        }
        return !isHeaderBannerDismissed && (state.isLoaded || state.isLoading) && items.isNotEmpty
    }

    private let itemProvider: POSItemProvider
    private let selectedItemSubject: PassthroughSubject<POSItem, Never> = .init()

    let selectedItemPublisher: AnyPublisher<POSItem, Never>

    var itemsPublisher: Published<[POSItem]>.Publisher { $items }
    var statePublisher: Published<ItemListViewModel.ItemListState>.Publisher { $state }

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
            // (!) We cannot override the array anymore with new content, subsequent calls should append to existing items
            // Problem: Potentially stale data. Most likely this also should be done in Yosemite.
            if nextPage == 1 {
                items = try await itemProvider.providePointOfSaleItems(nextPage)
            } else {
                let newItems = try await itemProvider.providePointOfSaleItems(nextPage)
                items.append(contentsOf: newItems)
            }

            if items.count == 0 {
                state = .empty
                // If nothing is found let's reset the pagination counter
                currentPage = 0
                nextPage = 1
            } else {
                state = .loaded(items)
                // Problem: Sync issues.
                // Updating items via web may make some of these never found if pagination keeps counting forward
                currentPage = (currentPage + 1)
                nextPage = (nextPage + 1)
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
        // Problem: We need to evaluate which products appear after a Pull-To-Refresh
        // Right now would just call the next page, rather than the initial one.
        // await populatePointOfSaleItems()
        do {
            let freshFirstPageItems = try await itemProvider.providePointOfSaleItems(1)
            // This will throw errors if used straight-away:
            // `ForEach<Array<POSItem>, Int64, Button<ItemCardView>>: the ID 2956 occurs multiple times within the collection, this will give undefined results!`
            // While the product ID exists, the internals might have changed (eg: price), and we still need to update those, we
            // may need to not use productID as the identifiable prop.
            items.append(contentsOf: freshFirstPageItems)
        } catch {
            debugPrint(error.localizedDescription.debugDescription)
        }
    }

    func dismissBanner() {
        isHeaderBannerDismissed = true
        UserDefaults.standard.set(isHeaderBannerDismissed, forKey: BannerState.isSimpleProductsOnlyBannerDismissedKey)
    }

    func simpleProductsInfoButtonTapped() {
        showSimpleProductsModal = true
    }
}

extension ItemListViewModel {
    enum ItemListState: Equatable {
        case empty
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

        var isLoading: Bool {
            switch self {
            case .loading:
                return true
            default:
                return false
            }
        }

        var hasError: ErrorModel {
            switch self {
            case .error(let errorModel):
                return errorModel
            default:
                return ItemListViewModel.ErrorModel(title: "Unknown error",
                                                    subtitle: "Unknown error",
                                                    buttonText: "Retry")
            }
        }

        // Equatable conformance for testing:
        static func == (lhs: ItemListViewModel.ItemListState, rhs: ItemListViewModel.ItemListState) -> Bool {
            switch (lhs, rhs) {
            case (.empty, .empty):
                return true
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

    struct BannerState {
        static let isSimpleProductsOnlyBannerDismissedKey = "isSimpleProductsOnlyBannerDismissed"
    }
}

private extension ItemListViewModel {
    enum Constants {
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
