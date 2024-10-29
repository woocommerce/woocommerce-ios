import Combine
import SwiftUI
import protocol Yosemite.POSItem

final class ItemListViewModel: ItemListViewModelProtocol {
    let posModel: PointOfSaleAggregateModel

    var items: [POSItem] {
        posModel.allItems
    }

    @Published private(set) var state: ItemListState = .loading
    @Published private(set) var isHeaderBannerDismissed: Bool = false
    @Published var showSimpleProductsModal: Bool = false

    @Published private var currentPage: Int = Constants.initialPage

    var shouldShowHeaderBanner: Bool {
        // The banner it's shown as long as it hasn't already been dismissed once:
        if UserDefaults.standard.bool(forKey: BannerState.isSimpleProductsOnlyBannerDismissedKey) == true {
            return false
        }
        return !isHeaderBannerDismissed && (state.isLoaded || state.isLoading) && items.isNotEmpty
    }

    var statePublisher: Published<ItemListViewModel.ItemListState>.Publisher { $state }

    init(posModel: PointOfSaleAggregateModel) {
        self.posModel = posModel
    }

    func select(_ item: POSItem) {
        posModel.selected(item: item)
    }

    @MainActor
    func loadInitialItems() async {
        currentPage = Constants.initialPage
        do {
            state = .loading
            try await posModel.loadItems(pageNumber: currentPage)
            if items.count == 0 {
                state = .empty
            } else {
                state = .loaded(items)
            }
        } catch {
            state = .error(ErrorModel.errorOnLoadingProducts())
        }
    }

    @MainActor
    func loadNextItems() async {
        // TODO: Optimize API calls. gh-14186
        // If there are no more pages to fetch, we can avoid the next call.
        let nextPage = currentPage + 1
        await fetchPage(pageNumber: nextPage)
    }

    @MainActor
    private func fetchPage(pageNumber: Int) async {
        do {
            state = .loading
            try await posModel.loadItems(pageNumber: pageNumber)
            state = .loaded(items)
            currentPage = pageNumber
        } catch {
            state = .error(ErrorModel.errorOnLoadingProducts())
        }
    }

    @MainActor
    func reload() async {
        posModel.removeAllItems()
        await loadInitialItems()
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

        static func errorOnLoadingProducts() -> Self {
            ErrorModel(title: Constants.failedToLoadTitle,
                       subtitle: Constants.failedToLoadSubtitle,
                       buttonText: Constants.failedToLoadButtonTitle)
        }
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
        static let initialPage: Int = 1
    }
}
