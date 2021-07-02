import Foundation
import Yosemite
import protocol Storage.StorageManagerType

final class ReviewOrderViewModel {
    /// Quick access to header types for table view registration
    ///
    let allHeaderTypes: [UITableViewHeaderFooterView.Type] = {
        Section.SectionType.allCases.map { $0.headerType }
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

    /// Sections for order table view
    ///
    var sections: [Section] {
        return [productSection, customerSection, trackingSection].filter { !$0.rows.isEmpty }
    }
}

// MARK: -
//
private extension ReviewOrderViewModel {
    /// Product section setup
    ///
    var productSection: Section {
        let rows = order.items.map { Row.orderItem(item: $0) }
        return .init(type: .products, rows: rows)
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
            return Row.shippingMethod
        }()

        let addressRow: Row? = {
            let orderContainsOnlyVirtualProducts = products
                .filter { (product) -> Bool in
                    order.items.first(where: { $0.productID == product.productID}) != nil
                }
                .allSatisfy { $0.virtual == true }
            guard let shippingAddress = order.shippingAddress, !orderContainsOnlyVirtualProducts else {
                return nil
            }
            return Row.shippingAddress(address: shippingAddress)
        }()

        // TODO: billing row?

        let rows = [noteRow, shippingMethodRow, addressRow].compactMap { $0 }
        return .init(type: .customerInformation, rows: rows)
    }

    /// Tracking section setup
    ///
    var trackingSection: Section {
        // TODO: add order tracking & trackingIsReachable
        let trackingRow: Row? = {
//                guard !orderTracking.isEmpty else { return nil }
            return nil
        }()

        let trackingAddRow: Row? = {
            // Hide the section if the shipment
            // tracking plugin is not installed
//                guard trackingIsReachable else { return nil }
            return Row.trackingAdd
        }()

        let rows = [trackingRow, trackingAddRow].compactMap { $0 }
        return .init(type: .tracking, rows: rows)
    }
}

// MARK: - Section and row types for Review Order table view
//
extension ReviewOrderViewModel {
    struct Section {
        /// Section types for Review Order screen
        ///
        enum SectionType: CaseIterable {
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

        let type: SectionType
        let rows: [Row]

        init(type: SectionType, rows: [Row]) {
            self.type = type
            self.rows = rows
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
