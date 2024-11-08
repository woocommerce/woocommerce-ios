import Combine
import SwiftUI
import protocol Yosemite.POSItem
import protocol Yosemite.POSItemProvider

final class ItemListViewModel: ItemListViewModelProtocol {

    @Published private(set) var items: [POSItem] = []
    @Published private(set) var state: ItemListState = .initialLoading
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

    private let itemProvider: POSItemProvider
    private let selectedItemSubject: PassthroughSubject<POSItem, Never> = .init()

    let selectedItemPublisher: AnyPublisher<POSItem, Never>

    var itemsPublisher: Published<[POSItem]>.Publisher { $items }
    var statePublisher: Published<ItemListState>.Publisher { $state }

    init(itemProvider: POSItemProvider) {
        self.itemProvider = itemProvider
        selectedItemPublisher = selectedItemSubject.eraseToAnyPublisher()
    }

    func select(_ item: POSItem) {
        selectedItemSubject.send(item)
    }

    @MainActor
    func loadInitialItems() async {
        currentPage = Constants.initialPage
        do {
            state = .initialLoading
            items = try await itemProvider.providePointOfSaleItems(pageNumber: currentPage)
            if items.count == 0 {
                state = .empty
            } else {
                state = .loaded(items)
            }
        } catch {
            state = .error(ItemListErrorModel.errorOnLoadingProducts())
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
            let newItems = try await itemProvider.providePointOfSaleItems(pageNumber: pageNumber)
            let uniqueNewItems = newItems.filter { newItem in
                !items.contains(where: { $0.productID == newItem.productID })
            }
            // If there are no new items, we just return what was already in memory
            if uniqueNewItems.count == 0 {
                state = .loaded(items)
            } else {
                items.append(contentsOf: uniqueNewItems)
                state = .loaded(items)
                currentPage = pageNumber
            }
        } catch {
            state = .error(ItemListErrorModel.errorOnLoadingProducts())
        }
    }

    @MainActor
    func reload() async {
        items.removeAll()
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

struct ItemListErrorModel: Equatable {
    let title: String
    let subtitle: String
    let buttonText: String

    static func errorOnLoadingProducts() -> Self {
        ItemListErrorModel(title: Constants.failedToLoadTitle,
                           subtitle: Constants.failedToLoadSubtitle,
                           buttonText: Constants.failedToLoadButtonTitle)
    }
}

private extension ItemListErrorModel {
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

extension ItemListViewModel {
    struct BannerState {
        static let isSimpleProductsOnlyBannerDismissedKey = "isSimpleProductsOnlyBannerDismissed"
    }
}

private extension ItemListViewModel {
    enum Constants {
        static let initialPage: Int = 1
    }
}
