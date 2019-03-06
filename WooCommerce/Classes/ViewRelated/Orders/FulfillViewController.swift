import Foundation
import UIKit
import CocoaLumberjack

import Yosemite
import Gridicons



/// Renders the Order Fulfillment Interface
///
class FulfillViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet private var tableView: UITableView!

    /// Action Container View: Renders the Action Button.
    ///
    @IBOutlet private var actionView: UIView!

    /// Action Button (Fulfill!)
    ///
    @IBOutlet private var actionButton: UIButton!

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
        setupTableView()
        setupActionButton()
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
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Setup: TableView
    ///
    func setupTableView() {
        tableView.tableFooterView = actionView
        tableView.allowsSelection = false
    }

    ///Setup: Action Button!
    ///
    func setupActionButton() {
        let title = NSLocalizedString("Mark Order Complete", comment: "Fulfill Order Action Button")
        actionButton.setTitle(title, for: .normal)
        actionButton.applyPrimaryButtonStyle()
        actionButton.addTarget(self, action: #selector(fulfillWasPressed), for: .touchUpInside)
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [
            CustomerInfoTableViewCell.self,
            LeftImageTableViewCell.self,
            ProductDetailsTableViewCell.self
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


// MARK: - Action Handlers
//
extension FulfillViewController {

    /// Whenever the Fulfillment Action is pressed, we'll mark the order as Completed, and pull back to the previous screen.
    ///
    @IBAction func fulfillWasPressed() {
        // Capture these values for the undo closure
        let orderID = order.orderID
        let doneStatus = OrderStatusEnum.completed.rawValue
        let undoStatus = order.statusKey

        let done = updateOrderAction(siteID: order.siteID, orderID: orderID, statusKey: doneStatus)
        let undo = updateOrderAction(siteID: order.siteID, orderID: orderID, statusKey: undoStatus)

        WooAnalytics.shared.track(.orderFulfillmentCompleteButtonTapped)
        WooAnalytics.shared.track(.orderStatusChange, withProperties: ["id": order.orderID,
                                                                       "from": order.statusKey,
                                                                       "to": OrderStatusEnum.completed.rawValue])
        StoresManager.shared.dispatch(done)

        displayOrderCompleteNotice {
            WooAnalytics.shared.track(.orderMarkedCompleteUndoButtonTapped)
            WooAnalytics.shared.track(.orderStatusChangeUndo, withProperties: ["id": orderID])
            WooAnalytics.shared.track(.orderStatusChange, withProperties: ["id": orderID,
                                                                           "from": doneStatus,
                                                                           "to": undoStatus])
            StoresManager.shared.dispatch(undo)
        }

        AppRatingManager.shared.incrementSignificantEvent()
        navigationController?.popViewController(animated: true)
    }

    /// Returns an Order Update Action that will result in the specified Order Status updated accordingly.
    ///
    private func updateOrderAction(siteID: Int, orderID: Int, statusKey: String) -> Action {
        return OrderAction.updateOrder(siteID: siteID, orderID: orderID, statusKey: statusKey, onCompletion: { error in
            guard let error = error else {
                WooAnalytics.shared.track(.orderStatusChangeSuccess)
                return
            }

            WooAnalytics.shared.track(.orderStatusChangeFailed, withError: error)
            DDLogError("⛔️ Order Update Failure: [\(orderID).status = \(statusKey)]. Error: \(error)")

            self.displayErrorNotice(orderID: orderID)
        })
    }

    /// Displays the `Order Fulfilled` Notice. Whenever the `Undo` button gets pressed, we'll execute the `onUndoAction` closure.
    ///
    private func displayOrderCompleteNotice(onUndoAction: @escaping () -> Void) {
        let message = NSLocalizedString("Order marked as fulfilled", comment: "Order fulfillment success notice")
        let actionTitle = NSLocalizedString("Undo", comment: "Undo Action")
        let notice = Notice(title: message, feedbackType: .success, actionTitle: actionTitle, actionHandler: onUndoAction)

        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the `Unable to Fulfill Order` Notice.
    ///
    func displayErrorNotice(orderID: Int) {
        let title = NSLocalizedString(
            "Unable to fulfill order #\(orderID)",
            comment: "Content of error presented when Fullfill Order Action Failed. It reads: Unable to fulfill order #{order number}"
        )
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title, message: nil, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.fulfillWasPressed()
        }

        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
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
        let section = sections[section]

        guard let leftTitle = section.title else {
            return nil
        }

        let headerID = TwoColumnSectionHeaderView.reuseIdentifier
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: headerID) as? TwoColumnSectionHeaderView else {
            fatalError()
        }

        headerView.leftText = leftTitle
        headerView.rightText = section.secondaryTitle

        return headerView
    }
}


// MARK: - UITableViewDataSource Conformance
//
private extension FulfillViewController {

    /// Setup a given UITableViewCell instance to actually display the specified Row's Payload.
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
            setupTrackingAddCell(cell)
        }
    }

    /// Setup: Product Cell
    ///
    private func setupProductCell(_ cell: UITableViewCell, with item: OrderItem) {
        guard let cell = cell as? ProductDetailsTableViewCell else {
            fatalError()
        }

        let viewModel = OrderItemViewModel(item: item, currency: order.currency)

        cell.name = viewModel.name
        cell.quantity = viewModel.quantity
        cell.price = viewModel.price
        cell.tax = viewModel.tax
        cell.sku = viewModel.sku
    }

    /// Setup: Note Cell
    ///
    private func setupNoteCell(_ cell: UITableViewCell, with note: String) {
        guard let cell = cell as? LeftImageTableViewCell else {
            fatalError()
        }

        cell.leftImage = Gridicon.iconOfType(.quote).imageWithTintColor(.black)
        cell.labelText = note

        cell.isAccessibilityElement = true

        cell.accessibilityHint = NSLocalizedString(
            "Adds a note to an order",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to add an order note."
        )

        cell.accessibilityLabel = note
        cell.accessibilityTraits = .button
    }

    /// Setup: Address Cell
    ///
    private func setupAddressCell(_ cell: UITableViewCell, with address: Address?) {
        guard let cell = cell as? CustomerInfoTableViewCell else {
            fatalError()
        }

        guard let address = order.shippingAddress ?? order.billingAddress else {
            cell.title = NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
            cell.address = NSLocalizedString(
                "No address specified.",
                comment: "Fulfill order > customer info > where the physical shipping address would normally display."
            )

            return
        }

        cell.title = NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
        cell.name = address.fullNameWithCompany
        cell.address = address.formattedPostalAddress
    }

    /// Setup: Add Tracking Cell
    ///
    func setupTrackingAddCell(_ cell: UITableViewCell) {
        guard let cell = cell as? LeftImageTableViewCell else {
            fatalError()
        }

        cell.leftImage = Gridicon.iconOfType(.addOutline)
        cell.labelText = NSLocalizedString("Add Tracking", comment: "Add Tracking row label")
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension FulfillViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
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
    case address(shipping: Address?)

    /// Represents an "Add Tracking" Row
    ///
    case trackingAdd


    /// Returns the Row's Reuse Identifier
    ///
    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }

    /// Returns the Row's Cell Type
    ///
    var cellType: UITableViewCell.Type {
        switch self {
        case .address:
            return CustomerInfoTableViewCell.self
        case .note:
            return LeftImageTableViewCell.self
        case .product:
            return ProductDetailsTableViewCell.self
        case .trackingAdd:
            return LeftImageTableViewCell.self
        }
    }
}


// MARK: - Section: Represents a TableView Section
//
private struct Section {

    /// Section's Title
    ///
    let title: String?

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
            let title = NSLocalizedString("Product", comment: "Section header title for the product")
            let secondaryTitle = NSLocalizedString("Qty", comment: "Section header title - abbreviation for quantity")
            let rows = order.items.map { Row.product(item: $0) }

            return Section(title: title, secondaryTitle: secondaryTitle, rows: rows)
        }()

        let note: Section? = {
            guard let note = order.customerNote, note.isEmpty == false else {
                return nil
            }

            let title = NSLocalizedString("Customer Provided Note", comment: "Section title for a note from the customer")
            let row = Row.note(text: note)

            return Section(title: title, secondaryTitle: nil, rows: [row])
        }()

        let address: Section = {
            let title = NSLocalizedString("Customer Information", comment: "Section title for the customer's billing and shipping address")
            if let shippingAddress = order.shippingAddress {
                let row = Row.address(shipping: shippingAddress)

                return Section(title: title, secondaryTitle: nil, rows: [row])
            }

            let row = Row.address(shipping: order.billingAddress)

            return Section(title: title, secondaryTitle: nil, rows: [row])
        }()

// TODO: Tracking support to be added via #185
//        let tracking: Section = {
//            let title = NSLocalizedString("Optional Tracking Information", comment: "")
//            let row = Row.trackingAdd
//
//            return Section(title: title, secondaryTitle: nil, rows: [row])
//        }()

        return [products, note, address].compactMap { $0 }
    }
}
