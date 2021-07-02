import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class ReviewOrderViewModel {
    /// The order for review
    ///
    private let order: Order

    /// Products in the order
    ///
    private let products: [Product]

    /// StorageManager to load details of order from storage
    ///
    private let storageManager: StorageManagerType

    /// Reference to the StoresManager to dispatch Yosemite Actions.
    ///
    private let stores: StoresManager

    init(order: Order,
         products: [Product],
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.order = order
        self.products = products
        self.stores = stores
        self.storageManager = storageManager
    }
}

// MARK: - Data source for review order controller
//
extension ReviewOrderViewModel {
    /// Title for Review Order screen
    ///
    var screenTitle: String {
        Localization.screenTitle
    }

    /// Title for Product section
    ///
    var productionSectionTitle: String {
        order.items.count > 0 ? Localization.productsSectionTitle : Localization.productSectionTitle
    }

    /// Title for Customer section
    ///
    var customerSectionTitle: String {
        return Localization.customerSectionTitle
    }

    /// Title for Tracking section
    ///
    var trackingSectionTitle: String {
        return Localization.trackingSectionTitle
    }
}

// MARK: - Localization
//
private extension ReviewOrderViewModel {
    enum Localization {
        static let screenTitle = NSLocalizedString("Review Order", comment: "Title of Review Order screen")
        static let productSectionTitle = NSLocalizedString("Product", comment: "Product section title in Review Order screen if there is one product.")
        static let productsSectionTitle = NSLocalizedString("Products",
                                                            comment: "Product section title in Review Order screen if there is more than one product.")
        static let customerSectionTitle = NSLocalizedString("Customer", comment: "Customer info section title in Review Order screen")
        static let trackingSectionTitle = NSLocalizedString("Tracking", comment: "Tracking section title in Review Order screen")
    }
}
