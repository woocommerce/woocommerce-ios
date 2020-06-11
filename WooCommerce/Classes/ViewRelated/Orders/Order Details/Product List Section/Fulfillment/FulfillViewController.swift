import Foundation
import UIKit
import Yosemite
import Gridicons


/// Renders the Order Fulfillment Interface
///
final class FulfillViewController: UIViewController {

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
    private var sections = [Section]()

    /// Order to be Fulfilled
    ///
    private let order: Order

    /// Products in the Order
    ///
    private let products: [Product]?

    /// Shipping Lines from an Order
    ///
    private var shippingLines: [ShippingLine] {
        return order.shippingLines
    }

    /// First Shipping method from an order
    ///
    private var shippingMethod: String {
        return shippingLines.first?.methodTitle ?? String()
    }

    /// ResultsController fetching ShipemntTracking data
    ///
    private lazy var trackingResultsController: ResultsController<StorageShipmentTracking> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld",
                                    self.order.siteID,
                                    self.order.orderID)
        let descriptor = NSSortDescriptor(keyPath: \StorageShipmentTracking.dateShipped, ascending: true)

        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Order shipment tracking list
    ///
    private var orderTracking: [ShipmentTracking] {
        return trackingResultsController.fetchedObjects
    }

    /// Indicates if we consider the shipment tracking plugin as reachable
    /// https://github.com/woocommerce/woocommerce-ios/issues/852#issuecomment-482308373
    ///
    private var trackingIsReachable: Bool = false

    private let imageService: ImageService = ServiceLocator.imageService

    /// Designated Initializer
    ///
    init(order: Order, products: [Product]?) {
        self.order = order
        self.products = products
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
        configureTrackingResultsController()
        reloadSections()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        syncTrackingsHidingAddButtonIfNecessary()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.updateFooterHeight()
    }

    private func syncTrackingsHidingAddButtonIfNecessary() {
        syncTracking { [weak self] error in
            if error == nil {
                self?.trackingIsReachable = true
            }

            self?.reloadSections()
            self?.tableView.reloadData()
        }
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
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
    }

    /// Setup: TableView
    ///
    func setupTableView() {
        let container = UIView(frame: CGRect(origin: .zero, size: CGSize(width: tableView.frame.width, height: 0)))
        container.addSubview(actionView)
        actionView.translatesAutoresizingMaskIntoConstraints = false
        container.pinSubviewToAllEdges(actionView)
        tableView.tableFooterView = container
    }

    ///Setup: Action Button!
    ///
    func setupActionButton() {
        let title = NSLocalizedString("Mark Order Complete", comment: "Fulfill Order Action Button")
        actionButton.setTitle(title, for: .normal)
        actionButton.applyPrimaryButtonStyle()
        actionButton.addTarget(self, action: #selector(fulfillWasPressed), for: .touchUpInside)
        actionButton.accessibilityIdentifier = "mark-order-complete-button"
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [
            CustomerInfoTableViewCell.self,
            CustomerNoteTableViewCell.self,
            LeftImageTableViewCell.self,
            TopLeftImageTableViewCell.self,
            EditableOrderTrackingTableViewCell.self,
            PickListTableViewCell.self
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
private extension FulfillViewController {

    /// Whenever the Fulfillment Action is pressed, we'll mark the order as Completed, and pull back to the previous screen.
    ///
    @IBAction func fulfillWasPressed() {
        // Capture these values for the undo closure
        let orderID = order.orderID
        let doneStatus = OrderStatusEnum.completed.rawValue
        let undoStatus = order.statusKey

        let done = updateOrderAction(siteID: order.siteID, orderID: orderID, statusKey: doneStatus)
        let undo = updateOrderAction(siteID: order.siteID, orderID: orderID, statusKey: undoStatus)

        ServiceLocator.analytics.track(.orderFulfillmentCompleteButtonTapped)
        ServiceLocator.analytics.track(.orderStatusChange, withProperties: ["id": order.orderID,
                                                                       "from": order.statusKey,
                                                                       "to": OrderStatusEnum.completed.rawValue])
        ServiceLocator.stores.dispatch(done)

        displayOrderCompleteNotice {
            ServiceLocator.analytics.track(.orderMarkedCompleteUndoButtonTapped)
            ServiceLocator.analytics.track(.orderStatusChangeUndo, withProperties: ["id": orderID])
            ServiceLocator.analytics.track(.orderStatusChange, withProperties: ["id": orderID,
                                                                           "from": doneStatus,
                                                                           "to": undoStatus])
            ServiceLocator.stores.dispatch(undo)
        }

        AppRatingManager.shared.incrementSignificantEvent()
        navigationController?.popViewController(animated: true)
    }

    /// Returns an Order Update Action that will result in the specified Order Status updated accordingly.
    ///
    func updateOrderAction(siteID: Int64, orderID: Int64, statusKey: String) -> Action {
        return OrderAction.updateOrder(siteID: siteID, orderID: orderID, statusKey: statusKey, onCompletion: { error in
            guard let error = error else {
                NotificationCenter.default.post(name: .ordersBadgeReloadRequired, object: nil)
                ServiceLocator.analytics.track(.orderStatusChangeSuccess)
                return
            }

            ServiceLocator.analytics.track(.orderStatusChangeFailed, withError: error)
            DDLogError("⛔️ Order Update Failure: [\(orderID).status = \(statusKey)]. Error: \(error)")

            self.displayErrorNotice(orderID: orderID)
        })
    }

    /// Displays the `Order Fulfilled` Notice. Whenever the `Undo` button gets pressed, we'll execute the `onUndoAction` closure.
    ///
    func displayOrderCompleteNotice(onUndoAction: @escaping () -> Void) {
        let message = NSLocalizedString("Order marked as fulfilled", comment: "Order fulfillment success notice")
        let actionTitle = NSLocalizedString("Undo", comment: "Undo Action")
        let notice = Notice(title: message, feedbackType: .success, actionTitle: actionTitle, actionHandler: onUndoAction)

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the `Unable to Fulfill Order` Notice.
    ///
    func displayErrorNotice(orderID: Int64) {
        let title = NSLocalizedString(
            "Unable to fulfill order #\(orderID)",
            comment: "Content of error presented when Fullfill Order Action Failed. It reads: Unable to fulfill order #{order number}"
        )
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title, message: nil, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.fulfillWasPressed()
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

    /// Displays the product detail screen for the provided ProductID
    ///
    func productWasPressed(for productID: Int64) {
        let loaderViewController = ProductLoaderViewController(productID: productID,
                                                               siteID: order.siteID)
        let navController = WooNavigationController(rootViewController: loaderViewController)
        present(navController, animated: true, completion: nil)
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

        setup(cell: cell, for: row, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = sections[section]

        guard let leftTitle = section.title,
            leftTitle.isEmpty != true  else {
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


// MARK: - Cell Configuration
//
private extension FulfillViewController {

    /// Setup a given UITableViewCell instance to actually display the specified Row's Payload.
    ///
    func setup(cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch row {
        case .product(let item):
            setupProductCell(cell, with: item)
        case .note(let text):
            setupCustomerNoteCell(cell, with: text)
        case .address(let shipping):
            setupAddressCell(cell, with: shipping)
        case .shippingMethod:
            setupShippingMethodCell(cell)
        case .tracking:
            setupTrackingCell(cell, at: indexPath)
        case .trackingAdd:
            setupTrackingAddCell(cell)
        }
    }

    /// Setup: Product Cell
    ///
    private func setupProductCell(_ cell: UITableViewCell, with item: OrderItem) {
        guard let cell = cell as? PickListTableViewCell else {
            fatalError()
        }

        let product = lookUpProduct(by: item.productOrVariationID)
        let viewModel = ProductDetailsCellViewModel(item: item, currency: order.currency, product: product)
        cell.selectionStyle = .default
        cell.configure(item: viewModel, imageService: imageService)
    }

    /// Setup: Customer Note Cell
    ///
    private func setupCustomerNoteCell(_ cell: UITableViewCell, with note: String) {
        guard let cell = cell as? TopLeftImageTableViewCell else {
            fatalError()
        }

        cell.imageView?.image = UIImage.quoteImage.imageWithTintColor(.black)
        cell.textLabel?.text = note

        cell.isAccessibilityElement = true
        cell.accessibilityLabel = note
    }

    /// Setup: Address Cell
    ///
    private func setupAddressCell(_ cell: UITableViewCell, with address: Address?) {
        guard let cell = cell as? CustomerInfoTableViewCell else {
            fatalError()
        }
        let shippingAddress = order.shippingAddress

        cell.title = NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
        cell.name = shippingAddress?.fullNameWithCompany
        cell.address = shippingAddress?.formattedPostalAddress ??
            NSLocalizedString(
                "No address specified.",
                comment: "Order details > customer info > shipping details. This is where the address would normally display."
        )
    }

    func setupShippingMethodCell(_ cell: UITableViewCell) {
        guard let cell = cell as? CustomerNoteTableViewCell else {
            fatalError()
        }

        cell.headline = NSLocalizedString("Shipping Method",
                                          comment: "Shipping method title for customer info cell")
        cell.body = shippingMethod.strippedHTML
        cell.selectionStyle = .none
    }

    /// Setup: Shipment Tracking Cell
    ///
    func setupTrackingCell(_ cell: UITableViewCell, at indexPath: IndexPath) {
        guard let cell = cell as? EditableOrderTrackingTableViewCell else {
            fatalError()
        }

        guard let tracking = orderTracking(at: indexPath) else {
            return
        }

        cell.topText = tracking.trackingProvider
        cell.middleText = tracking.trackingNumber
        cell.onDeleteTouchUp = { [weak self] in
            self?.presentDeleteAlert(at: indexPath)
        }

        if let dateShipped = tracking.dateShipped?.toString(dateStyle: .medium, timeStyle: .none) {
            cell.bottomText = String.localizedStringWithFormat(
                NSLocalizedString("Shipped %@",
                                  comment: "Date an item was shipped"),
                dateShipped)
        } else {
            cell.bottomText = NSLocalizedString("Not shipped yet",
                                                comment: "Order details > tracking. " +
                " This is where the shipping date would normally display.")
        }
    }

    /// Setup: Add Tracking Cell
    ///
    func setupTrackingAddCell(_ cell: UITableViewCell) {
        guard let cell = cell as? LeftImageTableViewCell else {
            fatalError()
        }

        let cellTextContent = NSLocalizedString("Add Tracking", comment: "Add Tracking row label")
        cell.leftImage = .addOutlineImage
        cell.imageView?.tintColor = .accent
        cell.labelText = cellTextContent

        cell.isAccessibilityElement = true

        cell.accessibilityLabel = cellTextContent
        cell.accessibilityTraits = .button
        cell.accessibilityHint = NSLocalizedString(
            "Adds tracking to an order.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to add tracking to an order. Should end with a period."
        )
        cell.accessibilityIdentifier = "fulfill-order-add-tracking-button"
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension FulfillViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch sections[indexPath.section].rows[indexPath.row] {

        case .trackingAdd:
            ServiceLocator.analytics.track(.orderFulfillmentAddTrackingButtonTapped)

            let viewModel = AddTrackingViewModel(order: order)
            let addTracking = ManualTrackingViewController(viewModel: viewModel)
            let navController = WooNavigationController(rootViewController: addTracking)
            present(navController, animated: true, completion: nil)

        case .product(let item):
            let productIDToLoad = item.variationID == 0 ? item.productID : item.variationID
            productWasPressed(for: productIDToLoad)

        case .tracking:
            break

        default:
            break
        }
    }
}


// MARK: - Shipment Tracking deletion
//
private extension FulfillViewController {
    func presentDeleteAlert(at indexPath: IndexPath) {
        guard let shipmentTracking = orderTracking(at: indexPath),
        let cell = tableView.cellForRow(at: indexPath) as? EditableOrderTrackingTableViewCell else {
            return
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text
        actionSheet.addCancelActionWithTitle(DeleteAction.cancel)
        actionSheet.addDestructiveActionWithTitle(DeleteAction.delete) { [weak self] _ in
            ServiceLocator.analytics.track(.orderFulfillmentDeleteTrackingButtonTapped)
            self?.deleteTracking(shipmentTracking)
        }

        let button = cell.getActionButton()
        let buttonRect = button.convert(button.bounds, to: tableView)

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = tableView
        popoverController?.sourceRect = buttonRect

        present(actionSheet, animated: true)
    }

    func deleteTracking(_ tracking: ShipmentTracking) {

        let siteID = order.siteID
        let orderID = order.orderID
        let trackingID = tracking.trackingID

        let statusKey = order.statusKey
        let providerName = tracking.trackingProvider ?? ""

        ServiceLocator.analytics.track(.orderTrackingDelete, withProperties: ["id": orderID,
                                                                         "status": statusKey,
                                                                         "carrier": providerName,
                                                                         "source": "order_fulfill"])

        let deleteTrackingAction = ShipmentAction.deleteTracking(siteID: siteID,
                                                                 orderID: orderID,
                                                                 trackingID: trackingID) { [weak self] error in
                                                                    if let error = error {
                                                                        DDLogError("⛔️ Delete Tracking Failure: orderID \(orderID). Error: \(error)")

                                                                        ServiceLocator.analytics.track(.orderTrackingDeleteFailed,
                                                                                                  withError: error)
                                                                        self?.displayDeleteErrorNotice(orderID: orderID, tracking: tracking)
                                                                        return
                                                                    }

                                                                    ServiceLocator.analytics.track(.orderTrackingDeleteSuccess)
                                                                    self?.syncTrackingsHidingAddButtonIfNecessary()
        }

        ServiceLocator.stores.dispatch(deleteTrackingAction)
    }

    /// Displays the `Unable to delete tracking` Notice.
    ///
    func displayDeleteErrorNotice(orderID: Int64, tracking: ShipmentTracking) {
        let title = NSLocalizedString(
            "Unable to delete tracking for order #\(orderID)",
            comment: "Content of error presented when Delete Shipment Tracking Action Failed. It reads: Unable to delete tracking for order #{order number}"
        )
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: title,
                            message: nil,
                            feedbackType: .error,
                            actionTitle: actionTitle) { [weak self] in
                                self?.deleteTracking(tracking)
        }

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }

}


// MARK: - Data fetch
//
private extension FulfillViewController {
    func syncTracking(onCompletion: ((Error?) -> Void)? = nil) {
        let orderID = order.orderID
        let siteID = order.siteID
        let action = ShipmentAction.synchronizeShipmentTrackingData(siteID: siteID,
                                                                    orderID: orderID) { error in
                                                                        if let error = error {
                                                                            DDLogError("⛔️ Error synchronizing tracking: \(error.localizedDescription)")
                                                                            onCompletion?(error)
                                                                            return
                                                                        }

                                                                        ServiceLocator.analytics.track(.orderTrackingLoaded, withProperties: ["id": orderID])

                                                                        onCompletion?(nil)
        }

        ServiceLocator.stores.dispatch(action)
    }

    func configureTrackingResultsController() {
        trackingResultsController.onDidChangeContent = { [weak self] in
            self?.reloadSections()
        }

        trackingResultsController.onDidResetContent = { [weak self] in
            self?.reloadSections()
        }

        try? trackingResultsController.performFetch()
    }

    func orderTracking(at indexPath: IndexPath) -> ShipmentTracking? {
        let orderIndex = indexPath.row
        guard orderTracking.indices.contains(orderIndex) else {
            return nil
        }

        return orderTracking[orderIndex]
    }

    func lookUpProduct(by productID: Int64) -> Product? {
        return products?.filter({ $0.productID == productID }).first
    }
}

// MARK: - Table view sections
//
private extension FulfillViewController {
    func reloadSections() {
        let productsSection: Section = {
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

        let address: Section? = {
            var rows: [Row] = []

            if shippingLines.count > 0 {
                rows.append(.shippingMethod)
            }

            let orderContainsOnlyVirtualProducts = products?.filter { (product) -> Bool in
                return order.items.first(where: { $0.productID == product.productID}) != nil
            }.allSatisfy { $0.virtual == true }

            let title = NSLocalizedString("Customer Information", comment: "Section title for the customer's billing and shipping address")
            if let shippingAddress = order.shippingAddress, orderContainsOnlyVirtualProducts == false {
                let row = Row.address(shipping: shippingAddress)
                rows.insert(row, at: 0)
                return Section(title: title, secondaryTitle: nil, rows: rows)
            }

            return nil
        }()

        let tracking: Section? = {
            let title = NSLocalizedString("Optional Tracking Information", comment: "")
            guard orderTracking.count > 0 else {
                return nil
            }

            let rows: [Row] = Array(repeating: .tracking, count: orderTracking.count)
            return Section(title: title, secondaryTitle: nil, rows: rows)
        }()

        let addTracking: Section? = {
            // Hide the section if the shipment
            // tracking plugin is not installed
            guard trackingIsReachable else {
                return nil
            }

            let title = orderTracking.count == 0 ? NSLocalizedString("Optional Tracking Information", comment: "") : nil
            let row = Row.trackingAdd

            return Section(title: title, secondaryTitle: nil, rows: [row])
        }()

        sections =  [productsSection, note, address, tracking, addTracking].compactMap { $0 }
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

    /// Represents a Shipping Method Row
    ///
    case shippingMethod

    /// Represents an "Add Tracking" Row
    ///
    case trackingAdd

    /// Represents a Shipment Tracking Row
    ///
    case tracking


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
        case .shippingMethod:
            return CustomerNoteTableViewCell.self
        case .note:
            return TopLeftImageTableViewCell.self
        case .product:
            return PickListTableViewCell.self
        case .trackingAdd:
            return LeftImageTableViewCell.self
        case .tracking:
            return EditableOrderTrackingTableViewCell.self
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


// MARK: - Alerts
private enum DeleteAction {
    static let cancel = NSLocalizedString("Cancel",
                                          comment: "Cancel the action sheet")
    static let delete = NSLocalizedString("Delete Tracking",
                                          comment: "Delete a Shipment Tracking")
}
