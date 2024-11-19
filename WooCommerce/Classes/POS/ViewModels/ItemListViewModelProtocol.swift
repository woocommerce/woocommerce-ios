import Combine
import Foundation
import protocol Yosemite.POSItem

protocol ItemListViewModelProtocol: ObservableObject {
    var isHeaderBannerDismissed: Bool { get }
    var shouldShowHeaderBanner: Bool { get }

    var selectedItemPublisher: AnyPublisher<POSItem, Never> { get }

    func select(_ item: POSItem)
    func dismissBanner()
}
