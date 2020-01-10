import Foundation
import Yosemite


// MARK: - Refunded Products View Model
//
final class RefundedProductsViewModel {
    /// Order we're observing.
    ///
    private(set) var order: Order

    /// Array of all refunded items from every refund.
    ///
    private var items: [OrderItemRefund]

    /// Condense order items into summarized data
    ///
    var summedItems: [OrderItemRefundSummary] {
        /// OrderItemRefund.orderItemID isn't useful for finding duplicates here,
        /// because multiple refunds cause orderItemIDs to be unique.
        /// Instead, we need to find duplicate *Products*.

        let currency = CurrencyFormatter()

        let grouped = Dictionary(grouping: items) { (item) in
            return item.hashValue
        }

        return grouped.compactMap { (_, items) in
            // Here we iterate over each group's items

            // All items should be equal except for quantity and price, so we pick the first
            guard let item = items.first else {
                // This should never happen, but let's be safe
                return nil
            }

            // Sum the quantities
            let totalQuantity = items.sum(\.quantity)
            // Sum the refunded amount
            let totalTax = items
                .compactMap( { currency.convertToDecimal(from: $0.totalTax) } )
                .reduce(NSDecimalNumber(value: 0), { $0.adding($1) })
            // Sum the total
            let total = items
                .compactMap( { currency.convertToDecimal(from: $0.total) } )
                .reduce(NSDecimalNumber(value: 0), { $0.adding($1) })

            return OrderItemRefundSummary(
                productID: item.productID,
                variationID: item.variationID,
                name: item.name,
                price: item.price,
                quantity: totalQuantity,
                sku: item.sku,
                total: total,
                totalTax: totalTax
            )
        }
    }

    /// The datasource that will be used to render the Refunded Products screen.
    ///
    private(set) lazy var dataSource: RefundedProductsDataSource = {
        return RefundedProductsDataSource(order: self.order, items: self.summedItems)
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
            let item = summedItems[indexPath.row]
            let productID = item.variationID == 0 ? item.productID : item.variationID
            let loaderViewController = ProductLoaderViewController(productID: productID,
                                                                   siteID: order.siteID,
                                                                   currency: order.currency)
            let navController = WooNavigationController(rootViewController: loaderViewController)
            viewController.present(navController, animated: true, completion: nil)
        }
    }
}
