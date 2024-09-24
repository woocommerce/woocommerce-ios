import CoreSpotlight
import Foundation

struct SpotlightManager {
    static func handleUserActivity(_ userActivity: NSUserActivity) {
        var type: WooActivityType?
        switch userActivity.activityType {
        case WooActivityType.dashboard.rawValue:
            AppDelegate.shared.tabBarController?.switchToMyStoreTab(animated: false)
            type = WooActivityType.dashboard
        case WooActivityType.orders.rawValue:
            AppDelegate.shared.tabBarController?.switchToOrdersTab(completion: nil)
            type = WooActivityType.orders
        case WooActivityType.products.rawValue:
            AppDelegate.shared.tabBarController?.switchToProductsTab(completion: nil)
            type = WooActivityType.products
        case WooActivityType.payments.rawValue:
            AppDelegate.shared.tabBarController?.presentPayments()
            type = WooActivityType.payments
        default:
            break
        }

        trackActivityBeingOpenedIfNecessary(with: type)
    }

    private static func trackActivityBeingOpenedIfNecessary(with type: WooActivityType?) {
        guard let type = type else {
            return
        }

        ServiceLocator.analytics.track(event: .Spotlight.activityWasOpened(with: type))
    }
}
