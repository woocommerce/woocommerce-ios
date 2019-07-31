import Foundation
import Yosemite

final class MainTabViewModel {
    var onReload: ((String?) -> Void)?

    func startObservingOrdersCount() {
        guard let siteID = StoresManager.shared.sessionManager.defaultStoreID else {
            DDLogError("# Error: Cannot fetch order count")
            return
        }

        let action = OrderAction.countProcessingOrders(siteID: siteID) { [weak self] orderCount, error in
            if error != nil {
                return
            }

            self?.processBadgeCount(orderCount)
        }

        StoresManager.shared.dispatch(action)
    }
}


private extension MainTabViewModel {
    enum Constants {
        static let ninePlus = "9+"
    }

    func processBadgeCount(_ orderCount: OrderCount?) {
        /// Exit early if there is not data, or the count is zero
        guard let orderCount = orderCount,
            let processingCount = orderCount[OrderStatusEnum.processing.rawValue]?.total,
            processingCount > 0 else {
            onReload?(nil)
            return
        }

        let returnValue = readableCount(processingCount)

        onReload?(returnValue)
    }

    private func readableCount(_ count: Int) -> String {
        return count > 9 ? Constants.ninePlus : String(count)
    }
}
