import Foundation
import UIKit
import Yosemite


/// Renders the Order Fulfillment Interface
///
class FulfillViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet private var tableView: UITableView!

    /// Sections to be Rendered
    ///
    private let sections: [Section]

    /// Order to be Fulfilled
    ///
    private let order: Order



    /// Designated Initializer
    ///
    init(order: Order) {
        self.order = order
        self.sections = Section.allSections(for: order)
        super.init(nibName: type(of: self).nibName, bundle: nil)
    }

    /// NSCoder Conformance
    ///
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }


    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationItem()
        setupMainView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
    }
}


// MARK: - Interface Initialization
//
private extension FulfillViewController {

    /// Setup: Navigation Item
    ///
    func setupNavigationItem() {
        title = NSLocalizedString("Fulfill Order #\(order.number)", comment: "Order Fulfillment Title")
    }

    /// Setup: Main View
    ///
    func setupMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [
            ProductDetailsTableViewCell.self,
            CustomerInfoTableViewCell.self
        ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters() {
        let headersAndFooters = [ TwoColumnSectionHeaderView.self ]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension FulfillViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = sections[indexPath.section].rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)

        setup(cell: cell, for: row)

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TwoColumnSectionHeaderView.reuseIdentifier) as? TwoColumnSectionHeaderView else {
            fatalError()
        }

        let section = sections[section]
        headerView.leftText = section.title.uppercased()
        headerView.rightText = section.secondaryTitle?.uppercased()

        return headerView
    }
}


// MARK: - UITableViewDataSource Conformance
//
private extension FulfillViewController {

    //
    ///
    func setup(cell: UITableViewCell, for row: Row) {
        switch row {
        case .product(let item):
            setupProductCell(cell, with: item)
        case .note(let text):
            setupNoteCell(cell, with: text)
        case .address(let shipping):
            setupAddressCell(cell, with: shipping)
        case .trackingAdd:
            setupTrackingCell(cell)
        }
    }

    ///
    ///
    private func setupProductCell(_ cell: UITableViewCell, with item: OrderItem) {
        guard let cell = cell as? ProductDetailsTableViewCell else {
            fatalError()
        }

        let viewModel = OrderItemViewModel(item: item, currencySymbol: order.currencySymbol)

        cell.name = viewModel.name
        cell.quantity = viewModel.quantity
        cell.price = viewModel.price
        cell.tax = viewModel.tax
        cell.sku = viewModel.sku
    }

    ///
    ///
    private func setupNoteCell(_ cell: UITableViewCell, with note: String) {

    }

    ///
    ///
    private func setupAddressCell(_ cell: UITableViewCell, with address: Address) {
        guard let cell = cell as? CustomerInfoTableViewCell else {
            fatalError()
        }

        let address = order.shippingAddress

        cell.title = NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
        cell.name = address.fullName
        cell.address = address.formattedPostalAddress
    }

    ///
    ///
    func setupTrackingCell(_ cell: UITableViewCell) {

    }
}


// MARK: - UITableViewDelegate Conformance
//
extension FulfillViewController: UITableViewDelegate {

}


// MARK: - Row: Represents a TableView Row
//
private enum Row {

    /// Represents a Product Row
    ///
    case product(item: OrderItem)

    /// Represents a Note Row
    ///
    case note(text: String)

    /// Represents an Address Row
    ///
    case address(shipping: Address)

    /// Represents an "Add Tracking" Row
    ///
    case trackingAdd

    /// Returns the Cell's Reuse Identifier
    ///
    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }

    ///
    ///
    var cellType: UITableViewCell.Type {
        switch self {
        case .product(_):
            return ProductDetailsTableViewCell.self
        case .note(_):
            return ProductDetailsTableViewCell.self
        case .address(_):
            return CustomerInfoTableViewCell.self
        case .trackingAdd:
            return ProductDetailsTableViewCell.self
        }
    }
}


// MARK: - Section: Represents a TableView Section
//
private struct Section {

    /// Section's Title
    ///
    let title: String

    /// Section's Secondary Title
    ///
    let secondaryTitle: String?

    /// Section's Row(s)
    ///
    let rows: [Row]
}


// MARK: - Section: Public Methods
//
private extension Section {

    /// Returns all of the Sections that should be rendered, in order to represent a given Order.
    ///
    static func allSections(for order: Order) -> [Section] {
        let products: Section = {
            let title = NSLocalizedString("Product", comment: "")
            let secondaryTitle = NSLocalizedString("Qty", comment: "")
            let rows = order.items.map { Row.product(item: $0) }

            return Section(title: title, secondaryTitle: secondaryTitle, rows: rows)
        }()

        let note: Section? = {
            guard let note = order.customerNote else {
                return nil
            }

            let title = NSLocalizedString("Customer Provided Note", comment: "")
            let row = Row.note(text: note)

            return Section(title: title, secondaryTitle: nil, rows: [row])
        }()

        let address: Section = {
            let title = NSLocalizedString("Customer Information", comment: "")
            let row = Row.address(shipping: order.shippingAddress)

            return Section(title: title, secondaryTitle: nil, rows: [row])
        }()

        let tracking: Section = {
            let title = NSLocalizedString("Optional Tracking Information", comment: "")
            let row = Row.trackingAdd

            return Section(title: title, secondaryTitle: nil, rows: [row])
        }()

        return [products, note, address, tracking].compactMap { $0 }
    }
}
