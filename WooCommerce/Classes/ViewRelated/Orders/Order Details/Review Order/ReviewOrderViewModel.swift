import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class ReviewOrderViewModel {
    /// Quick access to header types for table view registration
    ///
    let allHeaderTypes: [UITableViewHeaderFooterView.Type] = {
        [PrimarySectionHeaderView.self,
         TwoColumnSectionHeaderView.self]
    }()

    /// Quick access cell types for table view registration
    ///
    let allCellTypes: [UITableViewCell.Type] = {
        [ProductDetailsTableViewCell.self,
         CustomerNoteTableViewCell.self,
         CustomerInfoTableViewCell.self,
         WooBasicTableViewCell.self,
         OrderTrackingTableViewCell.self,
         LeftImageTableViewCell.self]
    }()

    /// The order for review
    ///
    let order: Order

    /// Products in the order
    ///
    private let products: [Product]

    /// StorageManager to load details of order from storage
    ///
    private let storageManager: StorageManagerType

    /// Reference to the StoresManager to dispatch Yosemite Actions.
    ///
    private let stores: StoresManager

    /// Indicates if the product cell will be configured with add on information or not.
    /// Property provided while "view add-ons" feature is in development.
    ///
    private let showAddOns: Bool

    /// Indicates if we consider the shipment tracking plugin as reachable
    ///
    private var trackingIsReachable: Bool = false

    /// Shipping labels for an Order
    ///
    var shippingLabels: [ShippingLabel] {
        return shippingLabelResultsController.fetchedObjects
    }

    /// Order shipment tracking list
    ///
    var orderTracking: [ShipmentTracking] {
        return trackingResultsController.fetchedObjects
    }

    /// Site's add-on groups.
    ///
    private var addOnGroups: [AddOnGroup] {
        return addOnGroupResultsController.fetchedObjects
    }

    /// AddOnGroup ResultsController.
    ///
    private lazy var addOnGroupResultsController: ResultsController<StorageAddOnGroup> = {
        let predicate = NSPredicate(format: "siteID == %lld", order.siteID)
        return ResultsController<StorageAddOnGroup>(storageManager: storageManager, matching: predicate, sortedBy: [])
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

    /// Shipment Tracking ResultsController.
    ///
    private lazy var trackingResultsController: ResultsController<StorageShipmentTracking> = {
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld",
                                    order.siteID,
                                    order.orderID)
        let descriptor = NSSortDescriptor(keyPath: \StorageShipmentTracking.dateShipped, ascending: true)

        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    init(order: Order,
         products: [Product],
         showAddOns: Bool,
         stores: StoresManager = ServiceLocator.stores,
         storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.order = order
        self.products = products
        self.showAddOns = showAddOns
        self.stores = stores
        self.storageManager = storageManager
    }

    /// Syncs shipment tracking data and triggers callback upon completion
    ///
    func syncTrackingsHidingAddButtonIfNecessary(onCompletion: @escaping () -> Void) {
        syncTracking { [weak self] error in
            if error == nil {
                self?.trackingIsReachable = true
            }
            onCompletion()
        }
    }
}

// MARK: - Data source for review order controller
//
extension ReviewOrderViewModel {

    /// Sections for order table view
    ///
    var sections: [Section] {
        return [productSection, customerSection, trackingSection].filter { !$0.rows.isEmpty }
    }

    /// Filter product for an order item
    ///
    func filterProduct(for item: OrderItem) -> Product? {
        products.first(where: { $0.productID == item.productID })
    }

    /// Filter addons for an order item
    ///
    func filterAddons(for item: OrderItem) -> [OrderItemAttribute] {
        let product = filterProduct(for: item)
        guard let product = product, showAddOns else {
            return []
        }
        return AddOnCrossreferenceUseCase(orderItemAttributes: item.attributes, product: product, addOnGroups: addOnGroups).addOnsAttributes()
    }

    /// Product Details cell view model for an order item
    ///
    func productDetailsCellViewModel(for item: OrderItem) -> ProductDetailsCellViewModel {
        let product = filterProduct(for: item)
        let addOns = filterAddons(for: item)
        return ProductDetailsCellViewModel(item: item, currency: order.currency, product: product, hasAddOns: !addOns.isEmpty)
    }

    /// Get shipment tracking at specified index of order.
    ///
    func orderTracking(at index: Int) -> ShipmentTracking? {
        guard orderTracking.indices.contains(index) else {
            return nil
        }
        return orderTracking[index]
    }
}

// MARK: - Order details
private extension ReviewOrderViewModel {
    /// Shipping address of the order
    ///
    var shippingAddress: Address? {
        order.shippingAddress
    }

    /// First Shipping method from an order
    ///
    var shippingMethod: String {
        return order.shippingLines.first?.methodTitle ?? String()
    }

    /// Syncs shipment tracking data and returns error if any
    ///
    func syncTracking(onCompletion: ((Error?) -> Void)? = nil) {
        let orderID = order.orderID
        let siteID = order.siteID
        let action = ShipmentAction.synchronizeShipmentTrackingData(
            siteID: siteID,
            orderID: orderID) { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing tracking: \(error.localizedDescription)")
                onCompletion?(error)
                return
            }

            ServiceLocator.analytics.track(.orderTrackingLoaded, withProperties: ["id": orderID])

            onCompletion?(nil)
        }
        stores.dispatch(action)
    }
}

// MARK: - Sections configuration
//
private extension ReviewOrderViewModel {
    /// Product section setup
    ///
    var productSection: Section {
        let rows = order.items.map { Row.orderItem(item: $0) }
        return .init(category: .products, rows: rows)
    }

    /// Customer section setup
    ///
    var customerSection: Section {
        let noteRow: Row? = {
            guard let note = order.customerNote, !note.isEmpty else {
                return nil
            }
            return Row.customerNote(text: note)
        }()

        let shippingMethodRow: Row? = {
            guard order.shippingLines.count > 0 else { return nil }
            return Row.shippingMethod(method: shippingMethod)
        }()

        let addressRow: Row? = {
            let orderContainsOnlyVirtualProducts = products
                .filter { (product) -> Bool in
                    order.items.first(where: { $0.productID == product.productID}) != nil
                }
                .allSatisfy { $0.virtual == true }
            guard let shippingAddress = shippingAddress, !orderContainsOnlyVirtualProducts else {
                return nil
            }
            return Row.shippingAddress(address: shippingAddress)
        }()

        let billingRow: Row = .billingDetail
        let rows = [noteRow, addressRow, shippingMethodRow, billingRow].compactMap { $0 }
        return .init(category: .customerInformation, rows: rows)
    }

    /// Tracking section setup
    ///
    var trackingSection: Section {
        let trackingRows: [Row] = {
            // Tracking section is hidden if there are non-empty non-refunded shipping labels.
            guard shippingLabels.nonRefunded.isEmpty else {
                return []
            }

            guard !orderTracking.isEmpty else { return [] }

            return Array(repeating: .tracking, count: orderTracking.count)

        }()

        let trackingAddRow: Row? = {
            // Add tracking section is hidden if there are non-empty non-refunded shipping labels.
            guard shippingLabels.nonRefunded.isEmpty else {
                return nil
            }

            // Hide the section if the shipment
            // tracking plugin is not installed
            guard trackingIsReachable else { return nil }
            return Row.trackingAdd
        }()

        let rows = (trackingRows + [trackingAddRow]).compactMap { $0 }
        return .init(category: .tracking, rows: rows)
    }
}

// MARK: - Section and row types for Review Order table view
//
extension ReviewOrderViewModel {
    struct Section {
        /// Section types for Review Order screen
        ///
        enum Category: CaseIterable {
            case products
            case customerInformation
            case tracking
        }

        /// Category of the section
        ///
        let category: Category

        /// Rows in the section
        ///
        let rows: [Row]

        /// UITableViewHeaderFooterView type for each section
        ///
        var headerType: UITableViewHeaderFooterView.Type {
            switch category {
            case .products:
                return PrimarySectionHeaderView.self
            case .customerInformation, .tracking:
                return TwoColumnSectionHeaderView.self
            }
        }

        init(category: Category, rows: [Row]) {
            self.category = category
            self.rows = rows
        }
    }

    /// Row types for Review Order screen
    ///
    enum Row {
        case orderItem(item: OrderItem)
        case customerNote(text: String)
        case shippingAddress(address: Address)
        case shippingMethod(method: String)
        case billingDetail
        case tracking
        case trackingAdd

        /// UITableViewCell type for each row type
        ///
        var cellType: UITableViewCell.Type {
            switch self {
            case .orderItem:
                return ProductDetailsTableViewCell.self
            case .customerNote:
                return CustomerNoteTableViewCell.self
            case .shippingAddress:
                return CustomerInfoTableViewCell.self
            case .shippingMethod:
                return CustomerNoteTableViewCell.self
            case .billingDetail:
                return WooBasicTableViewCell.self
            case .tracking:
                return OrderTrackingTableViewCell.self
            case .trackingAdd:
                return LeftImageTableViewCell.self
            }
        }
    }
}
