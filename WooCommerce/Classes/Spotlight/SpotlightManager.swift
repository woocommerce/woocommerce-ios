import CoreSpotlight
import Foundation
import Storage

struct SpotlightManager {
    static func handleUserActivity(_ userActivity: NSUserActivity) {
        var type: WooActivityType?
        switch userActivity.activityType {
        case CSSearchableItemActionType:
                    if let info = userActivity.userInfo,
                      let objectIdentifier = info[CSSearchableItemActivityIdentifier] as? String {
                        handleSearchableItemObjectIdentifier(objectIdentifier)
                    }
        case WooActivityType.dashboard.rawValue:
            MainTabBarController.switchToMyStoreTab()
            type = WooActivityType.dashboard
        case WooActivityType.orders.rawValue:
            MainTabBarController.switchToOrdersTab()
            type = WooActivityType.orders
        case WooActivityType.products.rawValue:
            MainTabBarController.switchToProductsTab()
            type = WooActivityType.products
        case WooActivityType.payments.rawValue:
            MainTabBarController.presentPayments()
            type = WooActivityType.payments
        default:
            break
        }

        trackActivityBeingOpenedIfNecessary(with: type)
    }

    private static func handleSearchableItemObjectIdentifier(_ identifier: String) {
        guard let objectURI = URL(string: identifier) else {
            return
        }

        let object = ServiceLocator.storageManager.managedObjectWithURI(objectURI)

        if let product = object as? Storage.Product {
            MainTabBarController.presentProduct(product.toReadOnly())
        }
    }

    private static func trackActivityBeingOpenedIfNecessary(with type: WooActivityType?) {
        guard let type = type else {
            return
        }

        ServiceLocator.analytics.track(event: WooAnalyticsEvent.Spotlight.activityWasOpened(with: type))
    }
}
