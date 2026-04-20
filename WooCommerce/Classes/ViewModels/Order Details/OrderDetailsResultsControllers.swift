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
    private lazy var productResultsController: GenericResultsController<StorageProduct, OrderDetailsProduct> = createProductResultsController()

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
    private(set) var products: [OrderDetailsProduct] = []

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
        guard shipments.isEmpty else {
            return shipments.compactMap { $0.shippingLabel }
        }
        return order.shippingLabels.sorted(by: { label1, label2 in
            if let shipmentID1 = label1.shipmentID,
               let shipmentID2 = label2.shipmentID {
                return shipmentID1.localizedStandardCompare(shipmentID2) == .orderedAscending
            }
            return label1.dateCreated < label2.dateCreated
        })
    }

    var shipments: [WooShippingShipment] {
        shipmentResultsController.fetchedObjects
    }

    /// Site's add-on groups.
    ///
    var addOnGroups: [AddOnGroup] {
        return addOnGroupResultsController.fetchedObjects
    }

    var sitePlugins: [SitePlugin] {
        return sitePluginsResultsController.fetchedObjects
    }

    var feeLines: [OrderFeeLine] {
        return order.fees
    }

    /// Shipping methods list
    ///
    var siteShippingMethods: [ShippingMethod] {
        return shippingMethodsResultsController.fetchedObjects
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
        configureAddOnGroupResultsController(onReload: onReload)
        configureSitePluginsResultsController(onReload: onReload)
        configureShippingMethodsResultsController(onReload: onReload)
        configureShipmentResultsController(onReload: onReload)
    }

    func update(order: Order) {
        self.order = order
        // Product and variation results controller depends on order items to load variations,
        // so we need to recreate it whenever receiving an updated order.
        self.productVariationResultsController = getProductVariationResultsController()
        self.productResultsController = createProductResultsController()
        if let onReload = onReload {
            configureProductVariationResultsController(onReload: onReload)
            configureProductResultsController(onReload: onReload)
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
        shipmentResultsController.onDidChangeContent = {
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
        } catch {
            DDLogError("⛔️ Unable to fetch shipments: \(error)")
        }
    }

    func configureStatusResultsController() {
        do {
            try statusResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Unable to fetch Order Statuses: \(error)")
        }
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

        do {
            try trackingResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Unable to fetch Order \(order.orderID) shipment tracking details: \(error)")
        }
    }

    private func configureProductResultsController(onReload: @escaping () -> Void) {
        productResultsController.onDidChangeContent = { [weak self] in
            guard let self else { return }
            products = productResultsController.fetchedObjects
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
            products = productResultsController.fetchedObjects
        } catch {
            DDLogError("⛔️ Unable to fetch Products for Site \(siteID): \(error)")
        }
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

        do {
            try refundResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Unable to fetch Refunds for Site \(siteID) and Order \(order.orderID): \(error)")
        }
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

        do {
            try addOnGroupResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Unable to fetch AddOnGroups for Site \(siteID): \(error)")
        }
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

        do {
            try sitePluginsResultsController.performFetch()
        } catch {
            DDLogError("⛔️ Unable to fetch Site Plugins for Site \(siteID): \(error)")
        }
    }

    private func configureShippingMethodsResultsController(onReload: @escaping () -> Void) {
        shippingMethodsResultsController.onDidChangeContent = {
            onReload()
        }

        shippingMethodsResultsController.onDidResetContent = { [weak self] in
            guard let self else { return }
            self.refetchAllResultsControllers()
            onReload()
        }

        do {
            try shippingMethodsResultsController.performFetch()
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

    func createProductResultsController() -> GenericResultsController<StorageProduct, OrderDetailsProduct> {
        let productIDs = order.items.map { $0.productID }
        let predicate = NSPredicate(format: "siteID == %lld AND productID IN %@", siteID, productIDs)
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return GenericResultsController<StorageProduct, OrderDetailsProduct>(
            storageManager: storageManager,
            matching: predicate,
            sortedBy: [descriptor],
            transformer: { OrderDetailsProduct(storageProduct: $0) }
        )
    }
}
