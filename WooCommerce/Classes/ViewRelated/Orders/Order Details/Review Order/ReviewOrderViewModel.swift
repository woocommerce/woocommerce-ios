import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class ReviewOrderViewModel {
    /// Calculate the new order item quantities and totals after refunded products have altered the fields
    ///
    var aggregateOrderItems: [AggregateOrderItem] {
        let orderItemsAfterCombiningWithRefunds = AggregateDataHelper.combineOrderItems(order.items, with: refunds)
        return orderItemsAfterCombiningWithRefunds
    }

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

    /// Site's add-on groups.
    ///
    private var addOnGroups: [AddOnGroup] {
        return addOnGroupResultsController.fetchedObjects
    }

    /// Refunds in an Order
    ///
    private var refunds: [Refund] {
        return refundResultsController.fetchedObjects
    }

    /// AddOnGroup ResultsController.
    ///
    private lazy var addOnGroupResultsController: ResultsController<StorageAddOnGroup> = {
        let predicate = NSPredicate(format: "siteID == %lld", order.siteID)
        return ResultsController<StorageAddOnGroup>(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    /// Refund Results Controller.
    ///
    private lazy var refundResultsController: ResultsController<StorageRefund> = {
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld",
                                    order.siteID,
                                    order.orderID)
        let descriptor = NSSortDescriptor(keyPath: \StorageRefund.dateCreated, ascending: true)

        return ResultsController<StorageRefund>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
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

    /// Trigger reload UI on change / reset of data
    ///
    func configureResultsControllers(onReload: @escaping () -> Void) {
        configureAddOnGroupResultsController(onReload: onReload)
        configureRefundResultsController(onReload: onReload)
    }
}

// MARK: - Data source for review order controller
//
extension ReviewOrderViewModel {

    /// Sections for order table view
    ///
    var sections: [Section] {
        // TODO: Add tracking section
        return [productSection, customerSection].filter { !$0.rows.isEmpty }
    }

    /// Filter product for an order item
    ///
    func filterProduct(for item: AggregateOrderItem) -> Product? {
        products.first(where: { $0.productID == item.productID })
    }

    /// Filter addons for an order item
    ///
    func filterAddons(for item: AggregateOrderItem) -> [OrderItemAttribute] {
        let product = filterProduct(for: item)
        guard let product = product, showAddOns else {
            return []
        }
        return AddOnCrossreferenceUseCase(orderItemAttributes: item.attributes, product: product, addOnGroups: addOnGroups).addOnsAttributes()
    }

    /// Product Details cell view model for an order item
    ///
    func productDetailsCellViewModel(for item: AggregateOrderItem) -> ProductDetailsCellViewModel {
        let product = filterProduct(for: item)
        let addOns = filterAddons(for: item)
        return ProductDetailsCellViewModel(aggregateItem: item, currency: order.currency, product: product, hasAddOns: !addOns.isEmpty)
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
}

// MARK: - Sections configuration
//
private extension ReviewOrderViewModel {
    /// Product section setup
    ///
    var productSection: Section {
        let rows = aggregateOrderItems.map { Row.orderItem(item: $0) }
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
        case orderItem(item: AggregateOrderItem)
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

/// Configure result controllers
///
private extension ReviewOrderViewModel {
    /// Trigger reload UI on change / reset of Add-on Groups
    ///
    func configureAddOnGroupResultsController(onReload: @escaping () -> Void) {
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

    /// Trigger reload UI on change / reset of Refunds
    ///
    func configureRefundResultsController(onReload: @escaping () -> Void) {
        refundResultsController.onDidChangeContent = {
            onReload()
        }

        refundResultsController.onDidResetContent = { [weak self] in
            guard let self = self else { return }
            self.refetchAllResultsControllers()
            onReload()
        }

        try? refundResultsController.performFetch()
    }

    /// Refetching all the results controllers is necessary after a storage reset in `onDidResetContent` callback and before reloading UI that
    /// involves more than one results controller.
    func refetchAllResultsControllers() {
        try? addOnGroupResultsController.performFetch()
        try? refundResultsController.performFetch()
    }
}
