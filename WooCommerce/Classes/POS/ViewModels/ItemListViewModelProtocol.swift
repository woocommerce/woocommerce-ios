import Combine
import Foundation
import protocol Yosemite.POSItem

protocol ItemListViewModelProtocol: ObservableObject {
    var items: [POSItem] { get }
    var state: ItemListViewModel.ItemListState { get }
    var isHeaderBannerDismissed: Bool { get }
    var shouldShowHeaderBanner: Bool { get }

    var selectedItemPublisher: AnyPublisher<POSItem, Never> { get }
    var itemsPublisher: Published<[POSItem]>.Publisher { get }
    var statePublisher: Published<ItemListViewModel.ItemListState>.Publisher { get }

    func select(_ item: POSItem)
    func populatePointOfSaleItems() async
    func reload() async
    func dismissBanner()
}
