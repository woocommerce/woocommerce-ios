import Foundation
import Yosemite


// MARK: - Refunded Products View Model
//
final class RefundedProductsViewModel {
    /// Order we're observing.
    ///
    private let order: Order

    /// Array of full refunds.
    ///
    private(set) var refunds: [Refund]

    /// The datasource that will be used to render the Order Details screen
    ///
    private(set) lazy var dataSource: RefundedProductsDataSource = {
        return RefundedProductsDataSource(order: self.order, refunds: self.refunds)
    }()

    /// Designated initializer.
    ///
    init(order: Order, refunds: [Refund]) {
        self.order = order
        self.refunds = refunds
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
    func reloadSections() {
        dataSource.reloadSections()
    }
}
