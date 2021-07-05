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
}

// MARK: - Data source for review order controller
//
extension ReviewOrderViewModel {
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
        Localization.customerSectionTitle
    }

    /// Title for Tracking section
    ///
    var trackingSectionTitle: String {
        Localization.trackingSectionTitle
    }

    /// Title for Customer Note cell
    ///
    var customerNoteTitle: String {
        Localization.customerNoteTitle
    }

    /// Title for Shipping Address cell
    ///
    var shippingAddressTitle: String {
        Localization.shippingAddressTitle
    }

    /// Title for Shipping Address if no address found
    ///
    var noAddressCellTitle: String {
        Localization.noAddressCellTitle
    }

    /// Title for Shipping Method cell
    ///
    var shippingMethodTitle: String {
        Localization.shippingMethodTitle
    }

    /// Title for Show Billing cell
    ///
    var showBillingTitle: String {
        Localization.showBillingTitle
    }

    /// Accessibility Label for Show Billing title
    ///
    var showBillingAccessibilityLabel: String {
        Localization.showBillingAccessibilityLabel
    }

    /// Accessibility Hint for Show Billing title
    ///
    var showBillingAccessibilityHint: String {
        Localization.showBillingAccessibilityHint
    }

    /// Sections for order table view
    ///
    var sections: [Section] {
        // TODO: Add tracking section
        return [productSection, customerSection].filter { !$0.rows.isEmpty }
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
    enum Row: Equatable {
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
        static let customerNoteTitle = NSLocalizedString("Customer Provided Note", comment: "Customer note row title")
        static let shippingAddressTitle = NSLocalizedString("Shipping Address", comment: "Shipping Address title for customer info section")
        static let noAddressCellTitle = NSLocalizedString(
            "No address specified.",
            comment: "Order details > customer info > shipping details. This is where the address would normally display."
        )
        static let shippingMethodTitle = NSLocalizedString("Shipping Method", comment: "Shipping method title for customer info section")
        static let showBillingTitle = NSLocalizedString("View Billing Information",
                                                        comment: "Button on bottom of Customer's information to show the billing details")
        static let showBillingAccessibilityLabel = NSLocalizedString(
            "View Billing Information",
            comment: "Accessibility label for the 'View Billing Information' button"
        )
        static let showBillingAccessibilityHint = NSLocalizedString(
            "Show the billing details for this order.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to view billing information."
        )
    }
}
