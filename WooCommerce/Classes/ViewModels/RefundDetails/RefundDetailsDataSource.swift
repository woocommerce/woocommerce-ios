import Foundation
import UIKit
import Yosemite


/// The main file for Refund Details data.
/// Must conform to NSObject so it can be the UITableViewDataSource.
///
final class RefundDetailsDataSource: NSObject {
    /// Refund
    ///
    private(set) var refund: Refund

    /// Order
    ///
    private(set) var order: Order

    /// Sections to be rendered
    ///
    private(set) var sections = [Section]()

    /// All the items inside a Refund
    private var items: [OrderItemRefund] {
        return refund.items
    }

    /// Products from a Refund.
    ///
    var products: [Product] {
        return resultsControllers.products
    }

    /// Refunds initializer.
    ///
    init(refund: Refund, order: Order) {
        self.refund = refund
        self.order = order
    }

    /// The results controllers used to display a refund
    ///
    private lazy var resultsControllers: RefundDetailsResultControllers = {
        return RefundDetailsResultControllers()
    }()

    /// Set up results controllers
    ///
    func configureResultsControllers(onReload: @escaping () -> Void) {
        resultsControllers.configureResultsControllers(onReload: onReload)
    }
}


// MARK: - Conformance to UITableViewDataSource
//
extension RefundDetailsDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)
        return cell
    }
}


// MARK: - Support for UITableViewDelegate
//
extension RefundDetailsDataSource {
    /// Set up table section headings
    ///
    func viewForHeaderInSection(_ section: Int, tableView: UITableView) -> UIView? {
        guard let leftText = sections[section].title else {
            return nil
        }

        let headerID = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? TwoColumnSectionHeaderView else {
            fatalError()
        }

        headerView.leftText = leftText
        headerView.rightText = sections[section].rightTitle

        return headerView
    }
}

// MARK: - Support for UITableViewDataSource
//
private extension RefundDetailsDataSource {
    /// Configure cellForRowAtIndexPath:
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as ProductDetailsTableViewCell:
            configureOrderItem(cell, at: indexPath)
        default:
            fatalError("Unidentified refund details row type")
        }
    }

    /// Setup: Product Cell
    ///
    private func configureOrderItem(_ cell: ProductDetailsTableViewCell, at indexPath: IndexPath) {
        let item = items[indexPath.row]
        let product = lookUpProduct(by: item.productID)
        let itemViewModel = OrderItemRefundViewModel(item: item,
                                                     currency: order.currency,
                                                     product: product)
        let imageService = ServiceLocator.imageService

        cell.selectionStyle = .default
        cell.configure(item: itemViewModel, imageService: imageService)
    }
}


// MARK: - Lookup products
//
extension RefundDetailsDataSource {
    func lookUpProduct(by productID: Int64) -> Product? {
        return products.filter({ $0.productID == productID }).first
    }
}


// MARK: - Sections
//
extension RefundDetailsDataSource {
    /// Setup: Sections
    ///
    func reloadSections() {
        let products: Section? = {
            guard items.isEmpty == false else {
                return nil
            }

            let rows: [Row] = Array(repeating: .orderItem, count: items.count)

            return Section(title: SectionTitle.product, rightTitle: SectionTitle.quantity, rows: rows)
        }()

        sections = [products].compactMap { $0 }
    }
}


// MARK: - Constants
//
extension RefundDetailsDataSource {
    /// Section Titles
    ///
    enum SectionTitle {
        static let product = NSLocalizedString("Product", comment: "Product section title")
        static let quantity = NSLocalizedString("Qty", comment: "Quantity abbreviation for section title")
    }

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case orderItem

        var reuseIdentifier: String {
            switch self {
            case .orderItem:
                return ProductDetailsTableViewCell.reuseIdentifier
            }
        }
    }

    /// Table Sections
    ///
    struct Section {
        let title: String?
        let rightTitle: String?
        let footer: String?
        let rows: [Row]

        init(title: String? = nil, rightTitle: String? = nil, footer: String? = nil, rows: [Row]) {
            self.title = title
            self.rightTitle = rightTitle
            self.footer = footer
            self.rows = rows
        }

        init(title: String? = nil, rightTitle: String? = nil, footer: String? = nil, row: Row) {
            self.init(title: title, rightTitle: rightTitle, footer: footer, rows: [row])
        }
    }
}
