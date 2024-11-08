import Combine
import Foundation
import protocol Yosemite.POSItem
@testable import WooCommerce

class MockItemListViewModel: ItemListViewModelProtocol {
    @Published var items: [any Yosemite.POSItem] = []

    @Published var state: ItemListState = .initialLoading
    var statePublisher: Published<ItemListState>.Publisher { $state }

    @Published var isHeaderBannerDismissed: Bool = false

    var shouldShowHeaderBanner: Bool = false

    lazy var selectedItemPublisher: AnyPublisher<any Yosemite.POSItem, Never> = selectedItemSubject.eraseToAnyPublisher()
    let selectedItemSubject: PassthroughSubject<any Yosemite.POSItem, Never> = .init()

    func select(_ item: any Yosemite.POSItem) {
    }

    func loadInitialItems() async {
    }

    func loadNextItems() async {
    }

    func reload() async {
    }

    func dismissBanner() {
    }
}
