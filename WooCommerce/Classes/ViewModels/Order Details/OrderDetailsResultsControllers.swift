import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// Results controllers used to render the Order Details view
///
final class OrderDetailsResultsControllers {
    private let storageManager: StorageManagerType

    private var order: Order
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

    /// ProductVariation ResultsController.
    ///
    private lazy var productVariationResultsController: ResultsController<StorageProductVariation> = getProductVariationResultsController()

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

    /// ShippingLabel Results Controller.
    ///
    private lazy var shippingLabelResultsController: ResultsController<StorageShippingLabel> = {
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld", order.siteID, order.orderID)
        let dateCreatedDescriptor = NSSortDescriptor(keyPath: \StorageShippingLabel.dateCreated, ascending: false)
        let shippingLabelIDDescriptor = NSSortDescriptor(keyPath: \StorageShippingLabel.shippingLabelID, ascending: false)
        return ResultsController<StorageShippingLabel>(storageManager: storageManager,
                                                       matching: predicate,
                                                       sortedBy: [dateCreatedDescriptor, shippingLabelIDDescriptor])
    }()

    /// AddOnGroup ResultsController.
    ///
    private lazy var addOnGroupResultsController: ResultsController<StorageAddOnGroup> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        return ResultsController<StorageAddOnGroup>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    /// Site Plugins ResultsController.
    ///
    private lazy var sitePluginsResultsController: ResultsController<StorageSitePlugin> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        return ResultsController<StorageSitePlugin>(storageManager: storageManager, matching: predicate, sortedBy: [])
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

    /// ProductVariations from an Order
    ///
    var productVariations: [ProductVariation] {
        return productVariationResultsController.fetchedObjects
    }

    /// Refunds in an Order
    ///
    var refunds: [Refund] {
        return refundResultsController.fetchedObjects
    }

    /// Shipping labels for an Order
    ///
    var shippingLabels: [ShippingLabel] {
        return shippingLabelResultsController.fetchedObjects
    }

    /// Site's add-on groups.
    ///
    var addOnGroups: [AddOnGroup] {
        return addOnGroupResultsController.fetchedObjects
    }

    var sitePlugins: [SitePlugin] {
        return sitePluginsResultsController.fetchedObjects
    }

    /// Completion handler for when results controllers reload.
    ///
    var onReload: (() -> Void)?

    init(order: Order,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.order = order
        self.siteID = order.siteID
        self.storageManager = storageManager
    }

    func configureResultsControllers(onReload: @escaping () -> Void) {
        self.onReload = onReload
        configureStatusResultsController()
        configureTrackingResultsController(onReload: onReload)
        configureProductResultsController(onReload: onReload)
        configureProductVariationResultsController(onReload: onReload)
        configureRefundResultsController(onReload: onReload)
        configureShippingLabelResultsController(onReload: onReload)
        configureAddOnGroupResultsController(onReload: onReload)
        configureSitePluginsResultsController(onReload: onReload)
    }

    func update(order: Order) {
        self.order = order
        // Product variation results controller depends on order items to load variations,
        // so we need to recreate it whenever receiving an updated order.
        self.productVariationResultsController = getProductVariationResultsController()
        if let onReload = onReload {
            configureProductVariationResultsController(onReload: onReload)
        }
    }
}

// MARK: - Configuring results controllers
//
private extension OrderDetailsResultsControllers {

    func getProductVariationResultsController() -> ResultsController<StorageProductVariation> {
        let variationIDs = order.items.map(\.variationID).filter { $0 != 0 }
        let predicate = NSPredicate(format: "siteID == %lld AND productVariationID in %@", siteID, variationIDs)

        return ResultsController<StorageProductVariation>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }

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

    private func configureProductVariationResultsController(onReload: @escaping () -> Void) {
        productVariationResultsController.onDidChangeContent = {
            onReload()
        }

        productVariationResultsController.onDidResetContent = { [weak self] in
            guard let self = self else {
                return
            }
            self.refetchAllResultsControllers()
            onReload()
        }

        do {
            try productVariationResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Error fetching ProductVariations for Order \(order.orderID): \(error)")
        }
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

    private func configureShippingLabelResultsController(onReload: @escaping () -> Void) {
        shippingLabelResultsController.onDidChangeContent = {
            onReload()
        }

        shippingLabelResultsController.onDidResetContent = { [weak self] in
            guard let self = self else { return }
            self.refetchAllResultsControllers()
            onReload()
        }

        try? shippingLabelResultsController.performFetch()
    }

    private func configureAddOnGroupResultsController(onReload: @escaping () -> Void) {
        addOnGroupResultsController.onDidChangeContent = {
            onReload()
        }

        addOnGroupResultsController.onDidResetContent = { [weak self] in
            guard let self = self else { return }
            self.refetchAllResultsControllers()
            onReload()
        }

        try? addOnGroupResultsController.performFetch()
    }

    private func configureSitePluginsResultsController(onReload: @escaping () -> Void) {
        sitePluginsResultsController.onDidChangeContent = {
            onReload()
        }

        sitePluginsResultsController.onDidResetContent = { [weak self] in
            guard let self = self else { return }
            self.refetchAllResultsControllers()
            onReload()
        }

        try? sitePluginsResultsController.performFetch()
    }

    /// Refetching all the results controllers is necessary after a storage reset in `onDidResetContent` callback and before reloading UI that
    /// involves more than one results controller.
    func refetchAllResultsControllers() {
        try? productResultsController.performFetch()
        try? productVariationResultsController.performFetch()
        try? refundResultsController.performFetch()
        try? trackingResultsController.performFetch()
        try? statusResultsController.performFetch()
        try? shippingLabelResultsController.performFetch()
        try? addOnGroupResultsController.performFetch()
        try? sitePluginsResultsController.performFetch()
    }
}
