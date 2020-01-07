import Foundation
import Yosemite


// MARK: - Refunded Products View Model
//
final class RefundedProductsViewModel {
    /// Order we're observing.
    ///
    private(set) var order: Order

    /// Array of all refunded items.
    ///
    private(set) var items: [OrderItemRefund]

    /// The datasource that will be used to render the Refunded Products screen.
    ///
    private(set) lazy var dataSource: RefundedProductsDataSource = {
        return RefundedProductsDataSource(order: self.order, items: self.items)
    }()

    /// Designated initializer.
    ///
    init(order: Order, items: [OrderItemRefund]) {
        self.order = order
        self.items = items
    }

    /// Update the view model's order when notified
    ///
    func update(order newOrder: Order) {
        self.order = newOrder
    }
}

// MARK: - Configuring results controllers
//
extension RefundedProductsViewModel {
    func configureResultsControllers(onReload: @escaping () -> Void) {
        dataSource.configureResultsControllers(onReload: onReload)
    }

    func updateOrderStatus(order: Order) {
        update(order: order)
        dataSource.update(order: order)
    }
}


// MARK: - Register table view cells
//
extension RefundedProductsViewModel {
    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells(_ tableView: UITableView) {
        let cells = [
            ProductDetailsTableViewCell.self
        ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters(_ tableView: UITableView) {
        let headersAndFooters = [
            TwoColumnSectionHeaderView.self
        ]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }
}


// MARK: - Sections
extension RefundedProductsViewModel {
    /// Reload section data
    ///
    func reloadSections() {
        dataSource.reloadSections()
    }

    /// Handle taps on cells
    ///
    func tableView(_ tableView: UITableView,
                   in viewController: UIViewController,
                   didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch dataSource.sections[indexPath.section].rows[indexPath.row] {

        case .orderItemRefunded:
            let item = items[indexPath.row]
            let productID = item.variationID == 0 ? item.productID : item.variationID
            let loaderViewController = ProductLoaderViewController(productID: productID,
                                                                   siteID: order.siteID,
                                                                   currency: order.currency)
            let navController = WooNavigationController(rootViewController: loaderViewController)
            viewController.present(navController, animated: true, completion: nil)
        }
    }
}


// MARK: - Syncing data. Yosemite related stuff
//
extension RefundedProductsViewModel {
    func syncOrder(onCompletion: ((Order?, Error?) -> ())? = nil) {
        let action = OrderAction.retrieveOrder(siteID: order.siteID, orderID: order.orderID) { (order, error) in
            guard let _ = order else {
                DDLogError("⛔️ Error synchronizing Order: \(error.debugDescription)")
                onCompletion?(nil, error)
                return
            }

            onCompletion?(order, nil)
        }

        ServiceLocator.stores.dispatch(action)
    }
}
