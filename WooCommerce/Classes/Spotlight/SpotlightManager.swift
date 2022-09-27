
import Foundation
import Storage

struct SpotlightManager {
    func handleSearchableItemObjectIdentifier(_ identifier: String) {
        guard let objectURI = URL(string: identifier) else {
            return
        }

        let object = ServiceLocator.storageManager.managedObjectWithURI(objectURI)

        if let product = object as? Storage.Product {
            MainTabBarController.presentProduct(product.toReadOnly())
        } else if let order = object as? Storage.Order {
            MainTabBarController.navigateToOrderDetails(with: order.orderID, siteID: order.siteID)
        }
    }
}
