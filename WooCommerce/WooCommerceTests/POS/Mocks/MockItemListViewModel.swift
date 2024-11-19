import Combine
import Foundation
import protocol Yosemite.POSItem
@testable import WooCommerce

class MockItemListViewModel: ItemListViewModelProtocol {
    @Published var isHeaderBannerDismissed: Bool = false

    func dismissBanner() {
    }
}
