import Foundation
import UIKit
import Yosemite


/// The main file for Refunded Products data.
/// Must conform to NSObject so it can be the UITableViewDataSource.
///
final class RefundedProductsDataSource: NSObject {
    /// Aggregate data for refunded products
    ///
    private(set) var refundedProducts: [AggregateOrderItem]

    /// Order
    ///
    private(set) var order: Order

    /// Sections to be rendered
    ///
    private(set) var sections = [Section]()

    /// Designated initializer.
    ///
    init(order: Order, refundedProducts: [AggregateOrderItem]) {
        self.order = order
        self.refundedProducts = refundedProducts
    }

    /// The results controllers used to display a refund
    ///
    private lazy var resultsControllers: RefundDetailsResultController = {
        return RefundDetailsResultController()
    }()

    /// Set up results controllers
    ///
    func configureResultsControllers(onReload: @escaping () -> Void) {
        resultsControllers.configureResultsControllers(onReload: onReload)
    }

    /// Update the data source's order when notified
    ///
    func update(order: Order) {
        self.order = order
    }

    /// Products from a Refund
    ///
    var products: [Product] {
        return resultsControllers.products
    }
}


// MARK: - Conformance to UITableViewDataSource
//
extension RefundedProductsDataSource: UITableViewDataSource {
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
extension RefundedProductsDataSource {
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
private extension RefundedProductsDataSource {
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as ProductDetailsTableViewCell where row == .orderItemRefunded:
            configureRefundedProduct(cell, at: indexPath)
        default:
            fatalError("Unidentified customer info row type")
        }
    }

    /// Setup: Refunded product details cell
    ///
    func configureRefundedProduct(_ cell: ProductDetailsTableViewCell, at indexPath: IndexPath) {
        let refundedProduct = refundedProducts[indexPath.row]
        let product = lookUpProduct(by: refundedProduct.productOrVariationID)
        let refundedProductViewModel = ProductDetailsCellViewModel(aggregateItem: refundedProduct,
                                                                    currency: order.currency,
                                                                    product: product)
        let imageService = ServiceLocator.imageService

        cell.selectionStyle = .default
        cell.configure(item: refundedProductViewModel, imageService: imageService)
    }
}


// MARK: - Lookup products
//
private extension RefundedProductsDataSource {
    func lookUpProduct(by productID: Int64) -> Product? {
        return products.filter({ $0.productID == productID }).first
    }
}


// MARK: - Sections
extension RefundedProductsDataSource {
    /// Setup: Sections
    ///
    func reloadSections() {
        let refundedProducts: Section? = {
            let rows: [Row] = Array(repeating: .orderItemRefunded, count: self.refundedProducts.count)

            return Section(title: SectionTitle.product, rightTitle: SectionTitle.quantity, rows: rows)
        }()

        sections = [refundedProducts].compactMap { $0 }
    }
}


// MARK: - Constants
//
extension RefundedProductsDataSource {
    /// Section Titles
    ///
    enum SectionTitle {
        static let product = NSLocalizedString("Refunded Products", comment: "Refunded Products section title")
        static let quantity = NSLocalizedString("Qty", comment: "Quantity abbreviation for section title")
    }

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case orderItemRefunded

        var reuseIdentifier: String {
            switch self {
            case .orderItemRefunded:
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
