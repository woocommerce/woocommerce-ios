import Foundation
import Yosemite


// MARK: - View Model for the Refunded Products view controller
//
final class RefundedProductsViewModel {
    /// Order we're observing.
    ///
    private(set) var order: Order

    /// Aggregate data for all OrderItemRefund.
    ///
    private var refundedProducts: [AggregateOrderItem]

    /// The datasource that will be used to render the Refunded Products screen.
    ///
    private(set) lazy var dataSource: RefundedProductsDataSource = {
        RefundedProductsDataSource(order: order, refundedProducts: refundedProducts)
    }()

    /// Designated initializer.
    ///
    init(order: Order, refundedProducts: [AggregateOrderItem]) {
        self.order = order
        self.refundedProducts = refundedProducts
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
    @MainActor
    func registerTableViewCells(_ tableView: UITableView) {
        tableView.registerNib(for: ProductDetailsTableViewCell.self)
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    @MainActor
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
}
