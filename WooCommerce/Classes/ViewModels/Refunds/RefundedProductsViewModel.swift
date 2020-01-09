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
    private(set) var items: [OrderItemRefund]

    /// Condense order items into summarized data
    ///
    var summedItems: [OrderItemRefundSummary] {
        /// OrderItemRefund.orderItemID isn't useful for finding duplicates here,
        /// because multiple refunds cause orderItemIDs to be unique.
        /// Instead, we need to find duplicate *Products*.

        let currency = CurrencyFormatter()

        // Sort the items by product ID
        let sorted = items.sorted(by: { $0.productID > $1.productID })

        // Get all the productIDs
        var productIDs = [Int64]()
        for item in sorted {
            productIDs.append(item.productID)
        }

        // Remove duplicate productIDs
        let uniqueProductIDs = Array(Set(productIDs))
        var variations = [OrderItemRefundSummary]()

        for productID in uniqueProductIDs {
            var productGroup = [OrderItemRefund]()
            var variationIDs = [Int64]()

            // Get every item that has the same productID
            for item in sorted {
                if item.productID == productID {
                    productGroup.append(item)
                    variationIDs.append(item.variationID)
                }
            }

            for repeatedItem in productGroup {
                let tax = currency.convertToDecimal(from: repeatedItem.totalTax)

                // See if a product with a variation is in the varitions array.
                let hasVariant = variations.contains { element in
                    if  element.productID == repeatedItem.productID &&
                        element.variationID == repeatedItem.variationID {
                        return true
                    }
                    return false
                }

                if hasVariant {
                    // Edit an existing variable product
                    let variant = variations.first(where: { $0.productID == repeatedItem.productID && $0.variationID == repeatedItem.variationID })
                    let tax = currency.convertToDecimal(from: repeatedItem.totalTax)
                    variant?.quantity += repeatedItem.quantity

                    if let totalTax = tax {
                        if let variantTax = variant?.totalTax {
                            variant?.totalTax = variantTax.adding(totalTax)
                        }
                    }
                } else {
                    // Make a new variable product
                    let variant = OrderItemRefundSummary(name: repeatedItem.name,
                                                         productID: repeatedItem.productID,
                                                         variationID: repeatedItem.variationID,
                                                         quantity: repeatedItem.quantity,
                                                         price: repeatedItem.price,
                                                         sku: repeatedItem.sku,
                                                         totalTax: tax)
                    variations.append(variant)
                }
            }
        }

        return variations
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
