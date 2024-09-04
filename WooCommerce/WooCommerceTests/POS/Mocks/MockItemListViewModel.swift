import Combine
import Foundation
import protocol Yosemite.POSItem
@testable import WooCommerce

class MockItemListViewModel: ItemListViewModelProtocol {
    @Published var items: [any Yosemite.POSItem] = []
    var itemsPublisher: Published<[any Yosemite.POSItem]>.Publisher { $items }

    @Published var state: WooCommerce.ItemListViewModel.ItemListState = .loading
    var statePublisher: Published<WooCommerce.ItemListViewModel.ItemListState>.Publisher { $state }

    @Published var isHeaderBannerDismissed: Bool = false

    var shouldShowHeaderBanner: Bool = false

    lazy var selectedItemPublisher: AnyPublisher<any Yosemite.POSItem, Never> = selectedItemSubject.eraseToAnyPublisher()
    let selectedItemSubject: PassthroughSubject<any Yosemite.POSItem, Never> = .init()

    func select(_ item: any Yosemite.POSItem) {
    }

    func populatePointOfSaleItems() async {
    }

    func reload() async {
    }

    func dismissBanner() {
    }
}
