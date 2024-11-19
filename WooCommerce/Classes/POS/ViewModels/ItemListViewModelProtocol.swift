import Combine
import Foundation
import protocol Yosemite.POSItem

protocol ItemListViewModelProtocol: ObservableObject {
    var isHeaderBannerDismissed: Bool { get }

    func dismissBanner()
}
