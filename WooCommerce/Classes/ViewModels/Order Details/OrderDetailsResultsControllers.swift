import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// Results controllers used to render the Order Details view
///
final class OrderDetailsResultsControllers {
    private let storageManager: StorageManagerType

    private let order: Order
    private let siteID: Int64

    /// Shipment Tracking ResultsController.
    ///
    private lazy var trackingResultsController: ResultsController<StorageShipmentTracking> = {
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld",
                                    self.order.siteID,
                                    self.order.orderID)
        let descriptor = NSSortDescriptor(keyPath: \StorageShipmentTracking.dateShipped, ascending: true)

        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Product ResultsController.
    ///
    private lazy var productResultsController: ResultsController<StorageProduct> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController<StorageProduct>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Status Results Controller.
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)

        return ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Refund Results Controller.
    ///
    private lazy var refundResultsController: ResultsController<StorageRefund> = {
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld",
                                    self.order.siteID,
                                    self.order.orderID)
        let descriptor = NSSortDescriptor(keyPath: \StorageRefund.dateCreated, ascending: true)

        return ResultsController<StorageRefund>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
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

    /// Refunds in an Order
    ///
    var refunds: [Refund] {
        return refundResultsController.fetchedObjects
    }

    init(order: Order,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.order = order
        self.siteID = order.siteID
        self.storageManager = storageManager
    }

    func configureResultsControllers(onReload: @escaping () -> Void) {
        configureStatusResultsController()
        configureTrackingResultsController(onReload: onReload)
        configureProductResultsController(onReload: onReload)
        configureRefundResultsController(onReload: onReload)
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

        trackingResultsController.onDidResetContent = { [weak self] in
            guard let self = self else {
                return
            }
            self.refetchAllResultsControllers()
            onReload()
        }

        try? trackingResultsController.performFetch()
    }

    private func configureProductResultsController(onReload: @escaping () -> Void) {
        productResultsController.onDidChangeContent = {
            onReload()
        }

        productResultsController.onDidResetContent = { [weak self] in
            guard let self = self else {
                return
            }
            self.refetchAllResultsControllers()
            onReload()
        }

        try? productResultsController.performFetch()
    }

    private func configureRefundResultsController(onReload: @escaping () -> Void) {
        refundResultsController.onDidChangeContent = {
            onReload()
        }

        refundResultsController.onDidResetContent = { [weak self] in
            guard let self = self else {
                return
            }
            self.refetchAllResultsControllers()
            onReload()
        }

        try? refundResultsController.performFetch()
    }

    /// Refetching all the results controllers is necessary after a storage reset in `onDidResetContent` callback and before reloading UI that
    /// involves more than one results controller.
    func refetchAllResultsControllers() {
        try? productResultsController.performFetch()
        try? refundResultsController.performFetch()
        try? trackingResultsController.performFetch()
        try? statusResultsController.performFetch()
    }
}
