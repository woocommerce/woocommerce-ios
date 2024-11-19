import Combine
import SwiftUI
import protocol Yosemite.POSItem

final class ItemListViewModel: ItemListViewModelProtocol {
    private let posModel: PointOfSaleAggregateModelProtocol

    @Published private(set) var isHeaderBannerDismissed: Bool = false

    private(set) var shouldShowGhostableItemCard: Bool = false

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

    init(posModel: PointOfSaleAggregateModelProtocol, shouldShowGhostableItemCard: Bool = false) {
        self.posModel = posModel
        self.shouldShowGhostableItemCard = shouldShowGhostableItemCard
        selectedItemPublisher = selectedItemSubject.eraseToAnyPublisher()
    }

    func select(_ item: POSItem) {
        selectedItemSubject.send(item)
    }

    func dismissBanner() {
        isHeaderBannerDismissed = true
        UserDefaults.standard.set(isHeaderBannerDismissed, forKey: BannerState.isSimpleProductsOnlyBannerDismissedKey)
    }
}

extension ItemListViewModel {
    struct BannerState {
        static let isSimpleProductsOnlyBannerDismissedKey = "isSimpleProductsOnlyBannerDismissed"
    }
}
