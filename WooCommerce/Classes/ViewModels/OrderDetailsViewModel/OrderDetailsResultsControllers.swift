import Foundation
import Yosemite

/// Results controllers used to render the Order Details view
///
final class OrderDetailsResultsControllers {
    private let order: Order

    // Shipment Tracking ResultsController.
    private lazy var trackingResultsController: ResultsController<StorageShipmentTracking> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld",
                                    self.order.siteID,
                                    self.order.orderID)
        let descriptor = NSSortDescriptor(keyPath: \StorageShipmentTracking.dateShipped, ascending: true)

        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Product ResultsController.
    ///
    private lazy var productResultsController: ResultsController<StorageProduct> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Status Results Controller.
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)

        return ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Order shipment tracking list
    ///
    var orderTracking: [ShipmentTracking] {
        return trackingResultsController.fetchedObjects
    }

    /// Order statuses list
    ///
    var currentSiteStatuses: [OrderStatus] {
        return statusResultsController.fetchedObjects
    }

    /// Products from an Order
    ///
    var products: [Product] {
        return productResultsController.fetchedObjects
    }

    init(order: Order) {
        self.order = order
    }

    func configureResultsControllers(onReload: @escaping () -> Void) {
        configureStatusResultsController()
        configureTrackingResultsController(onReload: onReload)
        configureProductResultsController(onReload: onReload)
    }
}

// MARK: - Configuring results controllers
//
private extension OrderDetailsResultsControllers {

    func configureStatusResultsController() {
        try? statusResultsController.performFetch()
    }

    private func configureTrackingResultsController(onReload: @escaping () -> Void) {
        trackingResultsController.onDidChangeContent = {
            onReload()
        }

        trackingResultsController.onDidResetContent = {
            onReload()
        }

        try? trackingResultsController.performFetch()
    }

    private func configureProductResultsController(onReload: @escaping () -> Void) {
        productResultsController.onDidChangeContent = {
            onReload()
        }

        productResultsController.onDidResetContent = {
            onReload()
        }

        try? productResultsController.performFetch()
    }
}
