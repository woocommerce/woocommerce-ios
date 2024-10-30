import Combine
import Foundation
import protocol Yosemite.POSItem

protocol ItemListViewModelProtocol: ObservableObject {
    var items: [POSItem] { get }
    var isHeaderBannerDismissed: Bool { get }
    var shouldShowHeaderBanner: Bool { get }

    func select(_ item: POSItem)
    func loadNextItems() async
    func dismissBanner()
}
