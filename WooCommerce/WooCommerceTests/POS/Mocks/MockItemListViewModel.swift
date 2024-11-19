import Combine
import Foundation
import protocol Yosemite.POSItem
@testable import WooCommerce

class MockItemListViewModel: ItemListViewModelProtocol {
    @Published var items: [any Yosemite.POSItem] = []

    @Published var state: ItemListState = .initialLoading
    var statePublisher: Published<ItemListState>.Publisher { $state }

    @Published var isHeaderBannerDismissed: Bool = false

    func dismissBanner() {
    }
}
