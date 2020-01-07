import Foundation
import UIKit
import Yosemite


/// The main file for Refund Details data.
/// Must conform to NSObject so it can be the UITableViewDataSource.
///
final class RefundDetailsDataSource: NSObject {
    /// Refund
    ///
    private let refund: Refund

    /// Order
    ///
    private let order: Order

    /// Sections to be rendered
    ///
    private(set) var sections = [Section]()

    /// All the items inside a Refund
    private var items: [OrderItemRefund] {
        return refund.items
    }

    /// Currency Formatter.
    ///
    private let currencyFormatter = CurrencyFormatter()

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
    private lazy var resultsControllers: RefundDetailsResultController = {
        return RefundDetailsResultController()
    }()

    /// Set up results controllers
    ///
    func configureResultsControllers(onReload: @escaping () -> Void) {
        resultsControllers.configureResultsControllers(onReload: onReload)
    }

    /// Refund Amount
    ///
    private var refundAmount: String {
        let formattedRefund = currencyFormatter.formatAmount(refund.amount, with: order.currency)

        return formattedRefund ?? String()
    }

    /// Refund Method
    ///
    private var refundMethod: String {
        guard refund.isAutomated == true else {
            let refundMethodTemplate = NSLocalizedString("Refunded manually via %@",
                                                         comment: "It reads, 'Refunded manually via <payment method>'")
            let refundMethodText = String.localizedStringWithFormat(refundMethodTemplate, order.paymentMethodTitle)

            return refundMethodText
        }

        let refundMethodTemplate = NSLocalizedString("Refunded via %@",
                                                     comment: "It reads, 'Refunded via <payment method>'")
        let refundMethodText = String.localizedStringWithFormat(refundMethodTemplate, order.paymentMethodTitle)

        return refundMethodText
    }

    /// Reason for refund note
    ///
    private var refundReason: String? {
        return refund.reason
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
        case let cell as LedgerTableViewCell:
            configureProductsRefund(cell, at: indexPath)
        case let cell as TwoColumnHeadlineFootnoteTableViewCell:
            configureRefundAmount(cell, at: indexPath)
        case let cell as WooBasicTableViewCell:
            configureRefundMethod(cell)
        case let cell as TopLeftImageTableViewCell:
            configureRefundNote(cell)
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

    /// Setup: ProductsRefund summary Cell
    ///
    private func configureProductsRefund(_ cell: LedgerTableViewCell, at indexPath: IndexPath) {
        cell.selectionStyle = .none
        let viewModel = RefundDetailsViewModel(order: order, refund: refund)
        cell.configure(with: viewModel)
    }

    /// Setup: Refund Amount Cell
    ///
    private func configureRefundAmount(_ cell: TwoColumnHeadlineFootnoteTableViewCell, at indexPath: IndexPath) {
        cell.selectionStyle = .none
        cell.leftText = RowTitle.refundAmount
        cell.rightText = refundAmount
        cell.hideFootnote()
    }

    /// Setup: Refund Method Cell
    ///
    private func configureRefundMethod(_ cell: WooBasicTableViewCell) {
        cell.selectionStyle = .none
        cell.bodyLabel?.text = refundMethod
        cell.applyPlainTextStyle()
    }

    /// Setup: Reason for Refund Note Cell
    ///
    private func configureRefundNote(_ cell: TopLeftImageTableViewCell) {
        cell.selectionStyle = .none
        cell.imageView?.image = UIImage.quoteImage
        cell.imageView?.tintColor = .text
        cell.textLabel?.text = refundReason
    }
}


// MARK: - Lookup products
//
private extension RefundDetailsDataSource {
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

            var rows: [Row] = Array(repeating: .orderItem, count: items.count)
            rows.append(.productsRefund)

            return Section(title: SectionTitle.product, rightTitle: SectionTitle.quantity, rows: rows)
        }()

        let details: Section = {
            let rows: [Row] = [.refundAmount, .refundMethod]

            return Section(title: SectionTitle.refundDetails, rightTitle: nil, rows: rows)
        }()

        let reason: Section? = {
            guard refundReason?.isEmpty == false else {
                return nil
            }

            let row: Row = .refundReason

            return Section(title: SectionTitle.refundReason, rightTitle: nil, row: row)
        }()

        sections = [products, details, reason].compactMap { $0 }
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
        static let refundDetails = NSLocalizedString("Refund Details", comment: "Refund Details section title")
        static let refundReason = NSLocalizedString("Reason for Refund", comment: "Refund note section title")
    }

    /// Row Titles
    ///
    enum RowTitle {
        static let refundAmount = NSLocalizedString("Refund Amount",
                                                    comment: "Refund Details page > Refund Details section > The label that marks the refunded amount")
    }

    /// Table Rows
    ///
    enum Row {
        /// Listed in the order they appear on screen
        case orderItem
        case productsRefund
        case refundAmount
        case refundMethod
        case refundReason

        var reuseIdentifier: String {
            switch self {
            case .orderItem:
                return ProductDetailsTableViewCell.reuseIdentifier
            case .productsRefund:
                return LedgerTableViewCell.reuseIdentifier
            case .refundAmount:
                return TwoColumnHeadlineFootnoteTableViewCell.reuseIdentifier
            case .refundMethod:
                return WooBasicTableViewCell.reuseIdentifier
            case .refundReason:
                return TopLeftImageTableViewCell.reuseIdentifier
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
