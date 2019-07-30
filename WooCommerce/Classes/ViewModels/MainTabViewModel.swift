import Foundation
import Yosemite

final class MainTabViewModel {
    var onReload: (() -> Void)?

    func startObservingOrdersCount() {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            DDLogError("# Error: Cannot fetch order count")
            return
        }

    }
}
