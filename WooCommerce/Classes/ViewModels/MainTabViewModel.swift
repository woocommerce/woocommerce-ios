import Foundation
import Yosemite

final class MainTabViewModel {
    var onReload: (() -> Void)?

    func startObservingOrdersCount() {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            DDLogError("# Error: Cannot fetch order count")
            return
        }

        let action = OrderAction.countProcessingOrders(siteID: siteID) { [weak self] orderCount, error in
            print("===== fetched order count ====")
            print(orderCount?[OrderStatusEnum.processing.rawValue]?.total)
            print("//////")
            self?.onReload?()
        }

        StoresManager.shared.dispatch(action)
    }
}
