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

    /// Shipping Methods ResultsController.
    ///
    private lazy var shippingMethodsResultsController: ResultsController<StorageShippingMethod> = {
        let predicate = NSPredicate(format: "siteID == %lld", siteID)
        return ResultsController<StorageShippingMethod>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    /// Shipments Results Controller.
    ///
    private lazy var shipmentResultsController: ResultsController<StorageWooShippingShipment> = {
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld",
                                    self.order.siteID,
                                    self.order.orderID)
        let descriptor = NSSortDescriptor(keyPath: \StorageWooShippingShipment.index, ascending: true)

        return ResultsController<StorageWooShippingShipment>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Order shipment tracking list
    ///
    private(set) var orderTracking: [ShipmentTracking] = []

    /// Order statuses list
    ///
    private(set) var currentSiteStatuses: [OrderStatus] = []

    /// Products from an Order
    ///
    private(set) var products: [ProductListItem] = []

    /// ProductVariations from an Order
    ///
    private(set) var productVariations: [ProductVariation] = []

    /// Refunds in an Order
    ///
    private(set) var refunds: [Refund] = []

    /// Shipping labels for an Order
    ///
    private(set) var shippingLabels: [ShippingLabel] = []

    private(set) var shipments: [WooShippingShipment] = []

    /// Site's add-on groups.
    ///
    private(set) var addOnGroups: [AddOnGroup] = []

    private(set) var sitePlugins: [SitePlugin] = []

    private(set) var feeLines: [OrderFeeLine] = []

    /// Shipping methods list
    ///
    private(set) var siteShippingMethods: [ShippingMethod] = []

    /// Completion handler for when results controllers reload.
    ///
    var onReload: (() -> Void)?

    init(order: Order,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.order = order
        self.siteID = order.siteID
        self.storageManager = storageManager
        feeLines = order.fees
        updateShippingLabels()
    }

    func configureResultsControllers(onReload: @escaping () -> Void) {
        self.onReload = onReload
        configureStatusResultsController()
        configureTrackingResultsController(onReload: onReload)
        configureProductResultsController(onReload: onReload)
        configureProductVariationResultsController(onReload: onReload)
        configureRefundResultsController(onReload: onReload)
        configureAddOnGroupResultsController(onReload: onReload)
        configureSitePluginsResultsController(onReload: onReload)
        configureShippingMethodsResultsController(onReload: onReload)
        configureShipmentResultsController(onReload: onReload)
    }

    func update(order: Order) {
        self.order = order
        feeLines = order.fees
        updateShippingLabels()
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

    func configureShipmentResultsController(onReload: @escaping () -> Void) {
        shipmentResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            shipments = shipmentResultsController.fetchedObjects
            onReload()
        }

        shipmentResultsController.onDidResetContent = { [weak self] in
            guard let self = self else {
                return
            }
            self.refetchAllResultsControllers()
            onReload()
        }

        do {
            try shipmentResultsController.performFetch()
            shipments = shipmentResultsController.fetchedObjects
        } catch {
            DDLogError("⛔️ Unable to fetch shipments: \(error)")
        }
    }

    func configureStatusResultsController() {
        do {
            try statusResultsController.performFetch()
            currentSiteStatuses = statusResultsController.fetchedObjects
        } catch {
            DDLogError("⛔️ Unable to fetch Order Statuses: \(error)")
        }
    }

    private func configureTrackingResultsController(onReload: @escaping () -> Void) {
        trackingResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            orderTracking = trackingResultsController.fetchedObjects
            onReload()
        }

        trackingResultsController.onDidResetContent = { [weak self] in
            guard let self = self else {
                return
            }
            self.refetchAllResultsControllers()
            onReload()
        }

        do {
            try trackingResultsController.performFetch()
            orderTracking = trackingResultsController.fetchedObjects
        } catch {
            DDLogError("⛔️ Unable to fetch Order \(order.orderID) shipment tracking details: \(error)")
        }
    }

    private func configureProductResultsController(onReload: @escaping () -> Void) {
        productResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            products = productResultsController.listItemObjects
            onReload()
        }

        productResultsController.onDidResetContent = { [weak self] in
            guard let self = self else {
                return
            }
            self.refetchAllResultsControllers()
            onReload()
        }

        do {
            try productResultsController.performFetch()
            products = productResultsController.listItemObjects
        } catch {
            DDLogError("⛔️ Unable to fetch Products for Site \(siteID): \(error)")
        }
    }

    private func configureProductVariationResultsController(onReload: @escaping () -> Void) {
        productVariationResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            productVariations = productVariationResultsController.fetchedObjects
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
            productVariations = productVariationResultsController.fetchedObjects
        } catch {
            DDLogError("⛔️ Error fetching ProductVariations for Order \(order.orderID): \(error)")
        }
    }

    private func configureRefundResultsController(onReload: @escaping () -> Void) {
        refundResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            refunds = refundResultsController.fetchedObjects
            onReload()
        }

        refundResultsController.onDidResetContent = { [weak self] in
            guard let self = self else {
                return
            }
            self.refetchAllResultsControllers()
            onReload()
        }

        do {
            try refundResultsController.performFetch()
            refunds = refundResultsController.fetchedObjects
        } catch {
            DDLogError("⛔️ Unable to fetch Refunds for Site \(siteID) and Order \(order.orderID): \(error)")
        }
    }

    private func configureAddOnGroupResultsController(onReload: @escaping () -> Void) {
        addOnGroupResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            addOnGroups = addOnGroupResultsController.fetchedObjects
            onReload()
        }

        addOnGroupResultsController.onDidResetContent = { [weak self] in
            guard let self = self else { return }
            self.refetchAllResultsControllers()
            onReload()
        }

        do {
            try addOnGroupResultsController.performFetch()
            addOnGroups = addOnGroupResultsController.fetchedObjects
        } catch {
            DDLogError("⛔️ Unable to fetch AddOnGroups for Site \(siteID): \(error)")
        }
    }

    private func configureSitePluginsResultsController(onReload: @escaping () -> Void) {
        sitePluginsResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            sitePlugins = sitePluginsResultsController.fetchedObjects
            onReload()
        }

        sitePluginsResultsController.onDidResetContent = { [weak self] in
            guard let self = self else { return }
            self.refetchAllResultsControllers()
            onReload()
        }

        do {
            try sitePluginsResultsController.performFetch()
            sitePlugins = sitePluginsResultsController.fetchedObjects
        } catch {
            DDLogError("⛔️ Unable to fetch Site Plugins for Site \(siteID): \(error)")
        }
    }

    private func configureShippingMethodsResultsController(onReload: @escaping () -> Void) {
        shippingMethodsResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            siteShippingMethods = shippingMethodsResultsController.fetchedObjects
            onReload()
        }

        shippingMethodsResultsController.onDidResetContent = { [weak self] in
            guard let self else { return }
            self.refetchAllResultsControllers()
            onReload()
        }

        do {
            try shippingMethodsResultsController.performFetch()
            siteShippingMethods = shippingMethodsResultsController.fetchedObjects
        } catch {
            DDLogError("⛔️ Unable to fetch Shipping Methods for Site \(siteID): \(error)")
        }
    }

    /// Refetching all the results controllers is necessary after a storage reset in `onDidResetContent` callback and before reloading UI that
    /// involves more than one results controller.
    func refetchAllResultsControllers() {
        try? productResultsController.performFetch()
        try? productVariationResultsController.performFetch()
        try? refundResultsController.performFetch()
        try? trackingResultsController.performFetch()
        try? statusResultsController.performFetch()
        try? addOnGroupResultsController.performFetch()
        try? sitePluginsResultsController.performFetch()
        try? shippingMethodsResultsController.performFetch()
    }

    func updateShippingLabels() {
        guard shipments.isEmpty else {
            shippingLabels = shipments.compactMap { $0.shippingLabel }
            return
        }
        shippingLabels =  order.shippingLabels.sorted(by: { label1, label2 in
            if let shipmentID1 = label1.shipmentID,
               let shipmentID2 = label2.shipmentID {
                return shipmentID1.localizedStandardCompare(shipmentID2) == .orderedAscending
            }
            return label1.dateCreated < label2.dateCreated
        })
    }
}
