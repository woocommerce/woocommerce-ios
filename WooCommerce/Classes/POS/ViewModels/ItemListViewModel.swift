import Combine
import SwiftUI
import protocol Yosemite.POSItem

final class ItemListViewModel: ItemListViewModelProtocol {
    let posModel: PointOfSaleAggregateModelProtocol

    @Published private(set) var isHeaderBannerDismissed: Bool = false
    @Published var showSimpleProductsModal: Bool = false

    @Published private var currentPage: Int = Constants.initialPage

    var shouldShowHeaderBanner: Bool {
        // The banner it's shown as long as it hasn't already been dismissed once:
        if UserDefaults.standard.bool(forKey: BannerState.isSimpleProductsOnlyBannerDismissedKey) == true {
            return false
        }
        switch posModel.itemListState {
        case .loading,
                .loaded:
            return !isHeaderBannerDismissed
        case .empty,
            .initialLoading,
            .error:
            return false
        }
    }

    private let selectedItemSubject: PassthroughSubject<POSItem, Never> = .init()

    let selectedItemPublisher: AnyPublisher<POSItem, Never>

    init(posModel: PointOfSaleAggregateModelProtocol) {
        self.posModel = posModel
        selectedItemPublisher = selectedItemSubject.eraseToAnyPublisher()
    }

    func select(_ item: POSItem) {
        selectedItemSubject.send(item)
    }

    @MainActor
    func loadInitialItems() async {
        try? await posModel.loadInitialItems()
    }

    @MainActor
    func loadNextItems() async {
        do {
            // TODO: Optimize API calls. gh-14186
            // If there are no more pages to fetch, we can avoid the next call.
            let nextPage = currentPage + 1
            try await posModel.loadItems(pageNumber: nextPage)
            currentPage = nextPage
        } catch {
            // No need to do anything; this avoids us incorrectly incrementing currentPage.
        }
    }

    @MainActor
    func reload() async {
        try? await posModel.reload()
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
    struct BannerState {
        static let isSimpleProductsOnlyBannerDismissedKey = "isSimpleProductsOnlyBannerDismissed"
    }
}

private extension ItemListViewModel {
    enum Constants {
        static let initialPage: Int = 1
    }
}
