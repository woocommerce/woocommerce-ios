import Combine
import Foundation
import protocol Yosemite.POSItem

protocol ItemListViewModelProtocol: ObservableObject {
    @available(*, deprecated, message: "`items` is due for removal, use `state` instead.")
    var items: [POSItem] { get }
    var state: ItemListState { get }
    var isHeaderBannerDismissed: Bool { get }
    var shouldShowHeaderBanner: Bool { get }

    var selectedItemPublisher: AnyPublisher<POSItem, Never> { get }
    var statePublisher: Published<ItemListState>.Publisher { get }

    func select(_ item: POSItem)
    func loadInitialItems() async
    func loadNextItems() async
    func reload() async
    func dismissBanner()
}
