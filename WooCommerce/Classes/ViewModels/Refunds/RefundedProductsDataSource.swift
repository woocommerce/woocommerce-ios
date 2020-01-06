import Foundation
import UIKit
import Yosemite


/// The main file for Refunded Products data.
/// Must conform to NSObject so it can be the UITableViewDataSource.
///
final class RefundedProductsDataSource: NSObject {
    /// Refunds
    ///
    private(set) var refunds: [Refund]

    /// Order
    ///
    private let order: Order

    /// Sections to be rendered
    ///
    private(set) var sections = [Section]()

    /// Designated initializer.
    ///
    init(order: Order, refunds: [Refund]) {
        self.order = order
        self.refunds = refunds
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
//        configure(cell, for: row, at: indexPath)

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


// MARK: - Constants
//
extension RefundedProductsDataSource {
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
