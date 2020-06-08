import Foundation
import Yosemite


// MARK: - MainTabViewModel Notifications
//
extension NSNotification.Name {

    /// Posted whenever an OrderBadge refresh is required.
    ///
    public static let ordersBadgeReloadRequired = Foundation.Notification.Name(rawValue: "com.woocommerce.ios.ordersBadgeReloadRequired")

    /// Posted whenever a refresh of Reviews tab is required.
    ///
    public static let reviewsBadgeReloadRequired = Foundation.Notification.Name(rawValue: "com.woocommerce.ios.reviewsBadgeReloadRequired")
}

final class MainTabViewModel {
    /// Callback to be executed when this view model receives new data
    /// passing the string to be presented in the badge as a parameter
    ///
    var onBadgeReload: ((String?) -> Void)?

    /// Bootstrap the data pipeline for the orders badge
    /// Fetches the initial badge count and observes notifications requesting a refresh
    /// The notification observed will be `ordersBadgeReloadRequired`
    ///
    func startObservingOrdersCount() {
        observeBadgeRefreshNotifications()
        requestBadgeCount()
    }
}


private extension MainTabViewModel {
    @objc func requestBadgeCount() {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            DDLogError("# Error: Cannot fetch order count")
            return
        }

        let action = OrderAction.countProcessingOrders(siteID: siteID) { [weak self] orderCount, error in
            if error != nil {
                return
            }

            self?.processBadgeCount(orderCount)
        }

        ServiceLocator.stores.dispatch(action)
    }

    func processBadgeCount(_ orderCount: OrderCount?) {
        // Exit early if there is not data, or the count is zero
        guard let orderCount = orderCount,
            let processingCount = orderCount[OrderStatusEnum.processing.rawValue]?.total,
            processingCount > 0 else {
            onBadgeReload?(nil)
            return
        }

        onBadgeReload?(NumberFormatter.localizedOrNinetyNinePlus(processingCount))
    }

    private func observeBadgeRefreshNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(requestBadgeCount),
                                               name: .ordersBadgeReloadRequired,
                                               object: nil)
    }
}
