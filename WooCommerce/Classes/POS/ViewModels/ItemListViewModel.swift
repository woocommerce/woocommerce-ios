import Combine
import SwiftUI
import protocol Yosemite.POSItem

final class ItemListViewModel: ItemListViewModelProtocol {
    let posModel: PointOfSaleAggregateModel

    @Published private(set) var isHeaderBannerDismissed: Bool = false
    @Published var showSimpleProductsModal: Bool = false

    private var currentPage: Int = Constants.initialPage

    var shouldShowHeaderBanner: Bool {
        // The banner it's shown as long as it hasn't already been dismissed once:
        if UserDefaults.standard.bool(forKey: BannerState.isSimpleProductsOnlyBannerDismissedKey) == true {
            return false
        }
        return !isHeaderBannerDismissed && posModel.allItems.isNotEmpty
    }

    init(posModel: PointOfSaleAggregateModel) {
        self.posModel = posModel
    }

    @MainActor
    func loadNextItems() async {
        // TODO: Optimize API calls. gh-14186
        // If there are no more pages to fetch, we can avoid the next call.
        let nextPage = currentPage + 1
        await posModel.loadItems(pageNumber: nextPage)
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
