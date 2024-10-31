import Combine
import Foundation
import protocol Yosemite.POSItem

protocol ItemListViewModelProtocol: ObservableObject {
    var isHeaderBannerDismissed: Bool { get }
    var shouldShowHeaderBanner: Bool { get }

    func loadNextItems() async
    func dismissBanner()
}
