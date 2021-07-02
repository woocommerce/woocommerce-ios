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

// MARK: - Section and row types for Review Order table view
//
extension ReviewOrderViewModel {
    /// Section types for Review Order screen
    ///
    enum Section: CaseIterable {
        case products
        case customerInformation
        case tracking

        var headerType: UITableViewHeaderFooterView.Type {
            switch self {
            case .products:
                return PrimarySectionHeaderView.self
            case .customerInformation, .tracking:
                return TwoColumnSectionHeaderView.self
            }
        }
    }

    /// Row types for Review Order screen
    ///
    enum Row {
        case orderItem(item: OrderItem)
        case customerNote(text: String)
        case shippingAddress(address: Address)
        case shippingMethod
        case billingDetail
        case tracking
        case trackingAdd

        var rowType: UITableViewCell.Type {
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

        static let allRowTypes: [UITableViewCell.Type] = {
            [ProductDetailsTableViewCell.self,
             CustomerNoteTableViewCell.self,
             CustomerInfoTableViewCell.self,
             WooBasicTableViewCell.self,
             OrderTrackingTableViewCell.self,
             LeftImageTableViewCell.self]
        }()
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
