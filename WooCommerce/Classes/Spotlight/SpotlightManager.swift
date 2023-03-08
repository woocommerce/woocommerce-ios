import CoreSpotlight
import Foundation

struct SpotlightManager {
    func handleUserActivity(_ userActivity: NSUserActivity) {
        switch userActivity.activityType {
        case WooActivityType.dashboard.rawValue:
            MainTabBarController.switchToMyStoreTab()
        case WooActivityType.orders.rawValue:
            MainTabBarController.switchToOrdersTab()
        case WooActivityType.products.rawValue:
            MainTabBarController.switchToProductsTab()
        case WooActivityType.hubMenu.rawValue:
            MainTabBarController.switchToHubMenuTab()
        case WooActivityType.payments.rawValue:
            MainTabBarController.presentPayments()
        default:
            break
        }
    }
}
