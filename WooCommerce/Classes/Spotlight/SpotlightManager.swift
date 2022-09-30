import CoreSpotlight
import Foundation
import Storage

struct SpotlightManager {
    func handleUserActivity(_ userActivity: NSUserActivity) {
        switch userActivity.activityType {
        case CSSearchableItemActionType:
            if let info = userActivity.userInfo,
              let objectIdentifier = info[CSSearchableItemActivityIdentifier] as? String {
                handleSearchableItemObjectIdentifier(objectIdentifier)
            }
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

    private func handleSearchableItemObjectIdentifier(_ identifier: String) {
        guard let objectURI = URL(string: identifier) else {
            return
        }

        let object = ServiceLocator.storageManager.managedObjectWithURI(objectURI)

        if let product = object as? Storage.Product {
            MainTabBarController.presentProduct(product.toReadOnly())
        } else if let order = object as? Storage.Order {
            MainTabBarController.navigateToOrderDetails(with: order.orderID, siteID: order.siteID)
        } else if let review = object as? Storage.ProductReview {
            MainTabBarController.presentProductReview(review.toReadOnly())
        }
    }
}
