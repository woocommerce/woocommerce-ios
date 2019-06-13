import UIKit
import Gridicons
import Contacts
import MessageUI
import Yosemite
import SafariServices


// MARK: - OrderDetailsViewController: Displays the details for a given Order.
//
final class OrderDetailsViewController: UIViewController {

    /// Main TableView.
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    private lazy var trackingResultsController: ResultsController<StorageShipmentTracking> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID = %ld AND orderID = %ld",
                                    viewModel.order.siteID,
                                    viewModel.order.orderID)
        let descriptor = NSSortDescriptor(keyPath: \StorageShipmentTracking.dateShipped, ascending: true)

        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Indicates if the Billing details should be rendered.
    ///
    private var displaysBillingDetails = false {
        didSet {
            reloadSections()
        }
    }

    /// EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Order> = {
        return EntityListener(storageManager: AppDelegate.shared.storageManager, readOnlyEntity: viewModel.order)
    }()

    /// ResultsController: Surrounds us. Binds the galaxy together. And also, keeps the UITableView <> (Stored) OrderStatuses in sync.
    ///
    private lazy var statusResultsController: ResultsController<StorageOrderStatus> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", StoresManager.shared.sessionManager.defaultStoreID ?? Int.min)
        let descriptor = NSSortDescriptor(key: "slug", ascending: true)

        return ResultsController<StorageOrderStatus>(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Sections to be rendered
    ///
    private var sections = [Section]()

    /// Order to be rendered!
    ///
    var viewModel: OrderDetailsViewModel! {
        didSet {
            reloadTableViewSectionsAndData()
        }
    }

    /// Order Notes
    ///
    private var orderNotes: [OrderNote] = [] {
        didSet {
            reloadTableViewSectionsAndData()
        }
    }

    /// Order shipment tracking list
    ///
    private var orderTracking: [ShipmentTracking] {
        return trackingResultsController.fetchedObjects
    }

    /// Indicates if we consider the shipment tracking plugin as reachable
    /// https://github.com/woocommerce/woocommerce-ios/issues/852#issuecomment-482308373
    ///
    private var trackingIsReachable: Bool = false

    /// Order statuses list
    ///
    private var currentSiteStatuses: [OrderStatus] {
        return statusResultsController.fetchedObjects
    }

    /// Haptic Feedback!
    ///
    private let hapticGenerator = UINotificationFeedbackGenerator()


    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
        registerTableViewCells()
        registerTableViewHeaderFooters()
        configureEntityListener()
        configureResultsController()
        configureTrackingResultsController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncNotes()
        syncTrackingsHidingAddButtonIfNecessary()
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


// MARK: - TableView Configuration
//
private extension OrderDetailsViewController {

    /// Setup: TableView
    ///
    func configureTableView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedSectionFooterHeight = Constants.rowHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.refreshControl = refreshControl
        tableView.separatorInset = .zero
    }

    /// Setup: Navigation
    ///
    func configureNavigation() {
        title = NSLocalizedString("Order #\(viewModel.order.number)", comment: "Order number title")

        // Don't show the Order details title in the next-view's back button
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)
    }

    /// Setup: EntityListener
    ///
    func configureEntityListener() {
        entityListener.onUpsert = { [weak self] order in
            guard let self = self else {
                return
            }

            let orderStatus = self.lookUpOrderStatus(for: order)
            self.viewModel = OrderDetailsViewModel(order: order, orderStatus: orderStatus)
        }

        entityListener.onDelete = { [weak self] in
            guard let self = self else {
                return
            }

            self.navigationController?.popViewController(animated: true)
            self.displayOrderDeletedNotice()
        }
    }

    /// Setup: Results Controller
    ///
    private func configureResultsController() {
        try? statusResultsController.performFetch()
    }

    func configureTrackingResultsController() {
        trackingResultsController.onDidChangeContent = { [weak self] in
            self?.reloadTableViewSectionsAndData()
        }

        trackingResultsController.onDidResetContent = { [weak self] in
            self?.reloadTableViewSectionsAndData()
        }

        try? trackingResultsController.performFetch()
    }

    /// Reloads the tableView's data, assuming the view has been loaded.
    ///
    func reloadTableViewDataIfPossible() {
        guard isViewLoaded else {
            return
        }

        tableView.reloadData()
    }

    /// Reloads the tableView's sections and data.
    ///
    func reloadTableViewSectionsAndData() {
        reloadSections()
        reloadTableViewDataIfPossible()
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [
            LeftImageTableViewCell.self,
            CustomerNoteTableViewCell.self,
            CustomerInfoTableViewCell.self,
            WooBasicTableViewCell.self,
            OrderNoteTableViewCell.self,
            PaymentTableViewCell.self,
            ProductDetailsTableViewCell.self,
            OrderTrackingTableViewCell.self,
            SummaryTableViewCell.self,
            FulfillButtonTableViewCell.self
        ]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    /// Registers all of the available TableViewHeaderFooters
    ///
    func registerTableViewHeaderFooters() {
        let headersAndFooters = [
            TwoColumnSectionHeaderView.self,
            ShowHideSectionFooter.self
        ]

        for kind in headersAndFooters {
            tableView.register(kind.loadNib(), forHeaderFooterViewReuseIdentifier: kind.reuseIdentifier)
        }
    }
}


// MARK: - Sections
//
private extension OrderDetailsViewController {

    /// Setup: Sections
    ///
    /// CustomerInformation Behavior:
    ///     When: Shipping == nil && Billing == nil     >>>     Display: Shipping = "No address specified" / Remove the rest
    ///     When: Shipping != nil && Billing == nil     >>>     Display: Shipping / Remove the rest
    ///     When: Shipping == nil && Billing != nil     >>>     Display: Shipping = "No address specified" / Billing / Footer
    ///     When: Shipping != nil && Billing != nil     >>>     Display: Shipping / Billing / Footer
    ///
    func reloadSections() {
        let summary = Section(row: .summary)

        let products: Section? = {
            guard viewModel.items.isEmpty == false else {
                return nil
            }

            var rows: [Row] = Array(repeating: .orderItem, count: viewModel.items.count)
            if viewModel.isProcessingPayment {
                rows.append(.fulfillButton)
            } else {
                rows.append(.details)
            }

            return Section(title: Title.product, rightTitle: Title.quantity, rows: rows)
        }()

        let customerNote: Section? = {
            guard viewModel.customerNote.isEmpty == false else {
                return nil
            }

            return Section(title: Title.customerNote, row: .customerNote)
        }()

        let customerInformation: Section = {
            guard let address = viewModel.order.billingAddress else {
                return Section(title: Title.information, row: .shippingAddress)
            }

            guard displaysBillingDetails else {
                return Section(title: Title.information, footer: Footer.showBilling, row: .shippingAddress)
            }

            var rows: [Row] = [.shippingAddress, .billingAddress]
            if address.hasPhoneNumber {
                rows.append(.billingPhone)
            }

            if address.hasEmailAddress {
                rows.append(.billingEmail)
            }

            return Section(title: Title.information, footer: Footer.hideBilling, rows: rows)
        }()

        let payment = Section(title: Title.payment, row: .payment)

        let tracking: Section? = {
            guard orderTracking.count > 0 else {
                return nil
            }

            let rows: [Row] = Array(repeating: .tracking, count: orderTracking.count)
            return Section(title: Title.tracking, rows: rows)
        }()

        let addTracking: Section? = {
            // Hide the section if the shipment
            // tracking plugin is not installed
            guard trackingIsReachable else {
                return nil
            }

            let title = orderTracking.count == 0 ? NSLocalizedString("Optional Tracking Information", comment: "") : nil
            let row = Row.trackingAdd

            return Section(title: title, rightTitle: nil, rows: [row])
        }()

        let notes: Section = {
            let rows = [.addOrderNote] + Array(repeating: Row.orderNote, count: orderNotes.count)
            return Section(title: Title.notes, rows: rows)
        }()

        sections = [summary, products, customerNote, customerInformation, payment, tracking, addTracking, notes].compactMap { $0 }
    }
}


// MARK: - Notices
//
private extension OrderDetailsViewController {

    /// Displays a Notice onscreen, indicating that the current Order has been deleted from the Store.
    ///
    func displayOrderDeletedNotice() {
        let message = String.localizedStringWithFormat(
            NSLocalizedString(
                "Order %@ has been deleted from your store",
                comment: "Displayed whenever the Details for an Order that just got deleted was onscreen. It reads: Order {order number} has been deleted from your store."
            ),
            viewModel.order.number
        )

        let notice = Notice(title: message, feedbackType: .error)
        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }
}

// MARK: - Action Handlers
//
extension OrderDetailsViewController {

    @objc func pullToRefresh() {
        WooAnalytics.shared.track(.orderDetailPulledToRefresh)
        let group = DispatchGroup()

        group.enter()
        syncOrder { _ in
            group.leave()
        }

        group.enter()
        syncNotes { _ in
            group.leave()
        }

        group.enter()
        syncTracking { _ in
            group.leave()
        }

        group.notify(queue: .main) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
}


// MARK: - Cell Configuration
//
private extension OrderDetailsViewController {
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as WooBasicTableViewCell where row == .details:
            configureDetails(cell: cell)
        case let cell as WooBasicTableViewCell where row == .billingEmail:
            configureBillingEmail(cell: cell)
        case let cell as WooBasicTableViewCell where row == .billingPhone:
            configureBillingPhone(cell: cell)
        case let cell as CustomerInfoTableViewCell where row == .billingAddress:
            configureBillingAddress(cell: cell)
        case let cell as CustomerInfoTableViewCell where row == .shippingAddress:
            configureShippingAddress(cell: cell)
        case let cell as CustomerNoteTableViewCell:
            configureCustomerNote(cell: cell)
        case let cell as LeftImageTableViewCell where row == .addOrderNote:
            configureNewNote(cell: cell)
        case let cell as OrderNoteTableViewCell:
            configureOrderNote(cell: cell, at: indexPath)
        case let cell as PaymentTableViewCell:
            configurePayment(cell: cell)
        case let cell as ProductDetailsTableViewCell:
            configureOrderItem(cell: cell, at: indexPath)
        case let cell as FulfillButtonTableViewCell:
            configureFulfillmentButton(cell: cell)
        case let cell as OrderTrackingTableViewCell:
            configureTracking(cell: cell, at: indexPath)
        case let cell as LeftImageTableViewCell where row == .trackingAdd:
            configureNewTracking(cell: cell)
        case let cell as SummaryTableViewCell:
            configureSummary(cell: cell)
        default:
            fatalError("Unidentified customer info row type")
        }
    }

    func configureBillingAddress(cell: CustomerInfoTableViewCell) {
        let billingAddress = viewModel.order.billingAddress

        cell.title = NSLocalizedString("Billing details", comment: "Billing title for customer info cell")
        cell.name = billingAddress?.fullNameWithCompany
        cell.address = billingAddress?.formattedPostalAddress ??
            NSLocalizedString("No address specified.",
                              comment: "Order details > customer info > billing details. This is where the address would normally display.")
    }

    func configureBillingEmail(cell: WooBasicTableViewCell) {
        guard let email = viewModel.order.billingAddress?.email else {
            // TODO: This should actually be an assert. To be revisited!
            return
        }

        cell.bodyLabel?.text = email
        cell.bodyLabel?.applyBodyStyle() // override the woo purple text
        cell.accessoryImage = Gridicon.iconOfType(.mail)

        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString("Email: %@",
                              comment: "Accessibility label that lets the user know the billing customer's email address"),
            email
        )

        cell.accessibilityHint = NSLocalizedString(
            "Composes a new email message to the billing customer.",
            comment: "VoiceOver accessibility hint, informing the user that the row can be tapped and an email composer view will appear."
        )
    }

    func configureBillingPhone(cell: WooBasicTableViewCell) {
        guard let phoneNumber = viewModel.order.billingAddress?.phone else {
            // TODO: This should actually be an assert. To be revisited!
            return
        }

        cell.bodyLabel?.text = phoneNumber
        cell.bodyLabel?.applyBodyStyle() // override the woo purple text
        cell.accessoryImage = Gridicon.iconOfType(.ellipsis)

        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString(
                "Phone number: %@",
                comment: "Accessibility label that lets the user know the data is a phone number before speaking the phone number."
            ),
            phoneNumber
        )

        cell.accessibilityHint = NSLocalizedString(
            "Prompts with the option to call or message the billing customer.",
            comment: "VoiceOver accessibility hint, informing the user that the row can be tapped to get to a prompt that lets them call or message the billing customer."
        )
    }

    func configureCustomerNote(cell: CustomerNoteTableViewCell) {
        cell.quote = viewModel.customerNote
    }

    func configureNewNote(cell: LeftImageTableViewCell) {
        cell.leftImage = viewModel.addNoteIcon
        cell.labelText = viewModel.addNoteText

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = NSLocalizedString(
            "Add a note button",
            comment: "Accessibility label for the 'Add a note' button"
        )

        cell.accessibilityHint = NSLocalizedString(
            "Composes a new order note.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to create a new order note."
        )
    }

    func configureOrderNote(cell: OrderNoteTableViewCell, at indexPath: IndexPath) {
        guard let note = note(at: indexPath) else {
            return
        }

        cell.isSystemAuthor = note.isSystemAuthor
        cell.isCustomerNote = note.isCustomerNote
        cell.dateCreated = note.dateCreated.toString(dateStyle: .long, timeStyle: .short)
        cell.contents = note.note.strippedHTML
    }

    func configurePayment(cell: PaymentTableViewCell) {
        cell.subtotalLabel.text = viewModel.subtotalLabel
        cell.subtotalValue.text = viewModel.subtotalValue

        cell.discountLabel.text = viewModel.discountLabel
        cell.discountValue.text = viewModel.discountValue
        cell.discountView.isHidden = viewModel.discountValue == nil

        cell.shippingLabel.text = viewModel.shippingLabel
        cell.shippingValue.text = viewModel.shippingValue

        cell.taxesLabel.text = viewModel.taxesLabel
        cell.taxesValue.text = viewModel.taxesValue
        cell.taxesView.isHidden = viewModel.taxesValue == nil

        cell.totalLabel.text = viewModel.totalLabel
        cell.totalValue.text = viewModel.totalValue

        cell.footerText = viewModel.paymentSummary

        cell.accessibilityElements = [cell.subtotalLabel as Any,
                                      cell.subtotalValue as Any,
                                      cell.discountLabel as Any,
                                      cell.discountValue as Any,
                                      cell.shippingLabel as Any,
                                      cell.shippingValue as Any,
                                      cell.taxesLabel as Any,
                                      cell.taxesValue as Any,
                                      cell.totalLabel as Any,
                                      cell.totalValue as Any]

        if let footerText = cell.footerText {
            cell.accessibilityElements?.append(footerText)
        }
    }

    func configureDetails(cell: WooBasicTableViewCell) {
        cell.bodyLabel?.text = viewModel.productDetails
        cell.bodyLabel?.applyBodyStyle() // override the custom purple with black
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
    }

    func configureOrderItem(cell: ProductDetailsTableViewCell, at indexPath: IndexPath) {
        let item = viewModel.items[indexPath.row]
        let itemViewModel = OrderItemViewModel(item: item, currency: viewModel.order.currency)
        cell.selectionStyle = FeatureFlag.productDetails.enabled ? .default : .none
        cell.name = itemViewModel.item.name
        cell.quantity = itemViewModel.quantity
        cell.price = itemViewModel.price
        cell.sku = itemViewModel.sku
    }

    func configureFulfillmentButton(cell: FulfillButtonTableViewCell) {
        cell.fulfillButton.setTitle(viewModel.fulfillTitle, for: .normal)
        cell.onFullfillTouchUp = { [weak self] in
            self?.fulfillWasPressed()
        }
    }

    func configureTracking(cell: OrderTrackingTableViewCell, at indexPath: IndexPath) {
        guard let tracking = orderTracking(at: indexPath) else {
            return
        }

        cell.topText = tracking.trackingProvider
        cell.middleText = tracking.trackingNumber

        cell.onEllipsisTouchUp = { [weak self] in
            self?.trackingWasPressed(at: indexPath)
        }

        if let dateShipped = tracking.dateShipped?.toString(dateStyle: .long, timeStyle: .none) {
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

    func configureNewTracking(cell: LeftImageTableViewCell) {
        let cellTextContent = NSLocalizedString("Add Tracking", comment: "Add Tracking row label")
        cell.leftImage = .addOutlineImage
        cell.labelText = cellTextContent

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = NSLocalizedString(
            "Add a tracking button",
            comment: "Accessibility label for the 'Add a tracking' button"
        )

        cell.accessibilityHint = NSLocalizedString(
            "Adds tracking to an order.",
            comment: "VoiceOver accessibility hint, informing the user that the button can be used to add tracking to an order. Should end with a period."
        )
    }

    func configureShippingAddress(cell: CustomerInfoTableViewCell) {
        let shippingAddress = viewModel.order.shippingAddress

        cell.title = NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
        cell.name = shippingAddress?.fullNameWithCompany
        cell.address = shippingAddress?.formattedPostalAddress ??
            NSLocalizedString(
                "No address specified.",
                comment: "Order details > customer info > shipping details. This is where the address would normally display."
        )
    }

    func configureSummary(cell: SummaryTableViewCell) {
        cell.title = viewModel.summaryTitle
        cell.dateCreated = viewModel.summaryDateCreated
        cell.onEditTouchUp = { [weak self] in
            self?.displayOrderStatusList()
        }

        cell.display(viewModel: viewModel)
    }
}


// MARK: - Sync'ing Helpers
//
private extension OrderDetailsViewController {
    func syncOrder(onCompletion: ((Error?) -> ())? = nil) {
        let action = OrderAction.retrieveOrder(siteID: viewModel.order.siteID, orderID: viewModel.order.orderID) { [weak self] (order, error) in
            guard let self = self, let order = order else {
                DDLogError("⛔️ Error synchronizing Order: \(error.debugDescription)")
                onCompletion?(error)
                return
            }

            let orderStatus = self.lookUpOrderStatus(for: order)
            self.viewModel = OrderDetailsViewModel(order: order, orderStatus: orderStatus)
            onCompletion?(nil)
        }

        StoresManager.shared.dispatch(action)
    }

    func syncTracking(onCompletion: ((Error?) -> Void)? = nil) {
        let orderID = viewModel.order.orderID
        let action = ShipmentAction.synchronizeShipmentTrackingData(siteID: viewModel.order.siteID,
                                                                    orderID: orderID) { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing tracking: \(error.localizedDescription)")
                onCompletion?(error)
                return
            }

            WooAnalytics.shared.track(.orderTrackingLoaded, withProperties: ["id": orderID])
            onCompletion?(nil)
        }

        StoresManager.shared.dispatch(action)
    }

    func syncNotes(onCompletion: ((Error?) -> ())? = nil) {
        let action = OrderNoteAction.retrieveOrderNotes(siteID: viewModel.order.siteID, orderID: viewModel.order.orderID) { [weak self] (orderNotes, error) in
            guard let orderNotes = orderNotes else {
                DDLogError("⛔️ Error synchronizing Order Notes: \(error.debugDescription)")
                self?.orderNotes = []
                onCompletion?(error)

                return
            }

            self?.orderNotes = orderNotes
            WooAnalytics.shared.track(.orderNotesLoaded, withProperties: ["id": self?.viewModel.order.orderID ?? 0])
            onCompletion?(nil)
        }

        StoresManager.shared.dispatch(action)
    }

    func lookUpOrderStatus(for order: Order) -> OrderStatus? {
        for orderStatus in currentSiteStatuses where orderStatus.slug == order.statusKey {
            return orderStatus
        }

        return nil
    }

    func deleteTracking(_ tracking: ShipmentTracking) {
        let siteID = viewModel.order.siteID
        let orderID = viewModel.order.orderID
        let trackingID = tracking.trackingID

        let statusKey = viewModel.order.statusKey
        let providerName = tracking.trackingProvider ?? ""

        WooAnalytics.shared.track(.orderTrackingDelete, withProperties: ["id": orderID,
                                                                         "status": statusKey,
                                                                         "carrier": providerName,
                                                                         "source": "order_detail"])

        let deleteTrackingAction = ShipmentAction.deleteTracking(siteID: siteID,
                                                                 orderID: orderID,
                                                                 trackingID: trackingID) { [weak self] error in
                                                                    if let error = error {
                                                                        DDLogError("⛔️ Order Details - Delete Tracking: orderID \(orderID). Error: \(error)")

                                                                        WooAnalytics.shared.track(.orderTrackingDeleteFailed,
                                                                                                  withError: error)
                                                                        self?.displayDeleteErrorNotice(orderID: orderID, tracking: tracking)
                                                                        return
                                                                    }

                                                                    WooAnalytics.shared.track(.orderTrackingDeleteSuccess)
                                                                    self?.reloadSections()

        }

        StoresManager.shared.dispatch(deleteTrackingAction)
    }
}


// MARK: - Actions
//
private extension OrderDetailsViewController {

    func toggleBillingFooter() {
        displaysBillingDetails = !displaysBillingDetails
        if displaysBillingDetails {
            WooAnalytics.shared.track(.orderDetailShowBillingTapped)
        } else {
            WooAnalytics.shared.track(.orderDetailHideBillingTapped)
        }
    }

    func fulfillWasPressed() {
        WooAnalytics.shared.track(.orderDetailFulfillButtonTapped)
        let fulfillViewController = FulfillViewController(order: viewModel.order)
        navigationController?.pushViewController(fulfillViewController, animated: true)
    }

    func trackingWasPressed(at indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? OrderTrackingTableViewCell else {
            return
        }

        displayShipmentTrackingAlert(from: cell, indexPath: indexPath)
    }

    func openTrackingDetails(_ tracking: ShipmentTracking) {
        guard let trackingURL = tracking.trackingURL?.addHTTPSSchemeIfNecessary(),
            let url = URL(string: trackingURL) else {
            return
        }

        WooAnalytics.shared.track(.orderDetailTrackPackageButtonTapped)
        displayWebView(url: url)
    }

    func displayWebView(url: URL) {
        let safariViewController = SFSafariViewController(url: url)
        present(safariViewController, animated: true, completion: nil)
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension OrderDetailsViewController: UITableViewDataSource {
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

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
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

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let lastSectionIndex = sections.count - 1

        if sections[section].footer != nil || section == lastSectionIndex {
            return UITableView.automaticDimension
        }

        return .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerText = sections[section].footer else {
            return nil
        }

        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShowHideSectionFooter.reuseIdentifier) as! ShowHideSectionFooter
        let image = displaysBillingDetails ? Gridicon.iconOfType(.chevronUp) : Gridicon.iconOfType(.chevronDown)
        cell.configure(text: footerText, image: image)
        cell.didSelectFooter = { [weak self] in
            guard let self = self else {
                return
            }

            let sections = IndexSet(integer: section)
            self.toggleBillingFooter()
            self.tableView.reloadSections(sections, with: .fade)
        }

        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension OrderDetailsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch sections[indexPath.section].rows[indexPath.row] {

        case .addOrderNote:
            WooAnalytics.shared.track(.orderDetailAddNoteButtonTapped)

            let newNoteViewController = NewNoteViewController()
            newNoteViewController.viewModel = viewModel

            let navController = WooNavigationController(rootViewController: newNoteViewController)
            present(navController, animated: true, completion: nil)
        case .trackingAdd:
            WooAnalytics.shared.track(.orderDetailAddTrackingButtonTapped)

            let addTrackingViewModel = AddTrackingViewModel(order: viewModel.order)
            let addTracking = ManualTrackingViewController(viewModel: addTrackingViewModel)
            let navController = WooNavigationController(rootViewController: addTracking)
            present(navController, animated: true, completion: nil)
        case .orderItem:
            if FeatureFlag.productDetails.enabled {
                let item = viewModel.order.items[indexPath.row]
                let productID = item.variationID == 0 ? item.productID : item.variationID
                let loaderViewController = ProductLoaderViewController(productID: productID,
                                                                       siteID: viewModel.order.siteID)
                let navController = WooNavigationController(rootViewController: loaderViewController)
                present(navController, animated: true, completion: nil)
            }
        case .details:
            WooAnalytics.shared.track(.orderDetailProductDetailTapped)
            performSegue(withIdentifier: Constants.productDetailsSegue, sender: nil)
        case .billingEmail:
            WooAnalytics.shared.track(.orderDetailCustomerEmailTapped)
            displayEmailComposerIfPossible()
        case .billingPhone:
            displayContactCustomerAlert(from: view)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard checkIfCopyingIsAllowed(for: indexPath) else {
            // Only allow the leading swipe action on the address rows
            return UISwipeActionsConfiguration(actions: [])
        }

        let copyActionTitle = NSLocalizedString("Copy", comment: "Copy address text button title — should be one word and as short as possible.")
        let copyAction = UIContextualAction(style: .normal, title: copyActionTitle) { [weak self] (action, view, success) in
            self?.copyText(at: indexPath)
            success(true)
        }
        copyAction.backgroundColor = StyleManager.wooCommerceBrandColor

        return UISwipeActionsConfiguration(actions: [copyAction])
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // No trailing action on any cell
        return UISwipeActionsConfiguration(actions: [])
    }

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return checkIfCopyingIsAllowed(for: indexPath)
    }

    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        guard action == #selector(copy(_:)) else {
            return
        }

        copyText(at: indexPath)
    }
}


// MARK: - Segues
//
extension OrderDetailsViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let productListViewController = segue.destination as? ProductListViewController {
            productListViewController.viewModel = viewModel
        }
    }
}


// MARK: - Convenience Methods
//
private extension OrderDetailsViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    func note(at indexPath: IndexPath) -> OrderNote? {
        // We need to subtract 1 here because the first order note row is the "Add Order" cell
        let noteIndex = indexPath.row - 1
        guard orderNotes.indices.contains(noteIndex) else {
            return nil
        }

        return orderNotes[noteIndex]
    }

    func orderTracking(at indexPath: IndexPath) -> ShipmentTracking? {
        let orderIndex = indexPath.row
        guard orderTracking.indices.contains(orderIndex) else {
            return nil
        }

        return orderTracking[orderIndex]
    }

    /// Checks if copying the row data at the provided indexPath is allowed
    ///
    /// - Parameter indexPath: index path of the row to check
    /// - Returns: true is copying is allowed, false otherwise
    ///
    func checkIfCopyingIsAllowed(for indexPath: IndexPath) -> Bool {
        let row = rowAtIndexPath(indexPath)
        switch row {
        case .billingAddress:
            if let _ = viewModel.order.billingAddress {
                return true
            }
        case .shippingAddress:
            if let _ = viewModel.order.shippingAddress {
                return true
            }
        case .tracking:
            if orderTracking(at: indexPath)?.trackingNumber.isEmpty == false {
                return true
            }
        default:
            break
        }

        return false
    }

    /// Sends the provided Row's text data to the pasteboard
    ///
    /// - Parameter indexPath: IndexPath to copy text data from
    ///
    func copyText(at indexPath: IndexPath) {
        let row = rowAtIndexPath(indexPath)

        switch row {
        case .billingAddress:
            sendToPasteboard(viewModel.order.billingAddress?.fullNameWithCompanyAndAddress)
        case .shippingAddress:
            sendToPasteboard(viewModel.order.shippingAddress?.fullNameWithCompanyAndAddress)
        case .tracking:
            sendToPasteboard(orderTracking(at: indexPath)?.trackingNumber, includeTrailingNewline: false)
        default:
            break // We only send text to the pasteboard from the address rows right meow
        }
    }

    /// Sends the provided text to the general pasteboard and triggers a success haptic. If the text param
    /// is nil, nothing is sent to the pasteboard.
    ///
    /// - Parameter
    ///   - text: string value to send to the pasteboard
    ///   - includeTrailingNewline: It true, insert a trailing newline; defaults to true
    ///
    func sendToPasteboard(_ text: String?, includeTrailingNewline: Bool = true) {
        guard var text = text, text.isEmpty == false else {
            return
        }

        if includeTrailingNewline {
            text += "\n"
        }

        UIPasteboard.general.string = text
        hapticGenerator.notificationOccurred(.success)
    }
}


// MARK: - Trackings alert
// Track / delete tracking alert
private extension OrderDetailsViewController {
    /// Displays an alert that offers deleting a shipment tracking or opening
    /// it in a webview
    ///

    func displayShipmentTrackingAlert(from sourceView: UIView, indexPath: IndexPath) {
        guard let tracking = orderTracking(at: indexPath) else {
            return
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = StyleManager.wooCommerceBrandColor

        actionSheet.addCancelActionWithTitle(TrackingAction.dismiss)

        if tracking.trackingURL?.isEmpty == false {
            actionSheet.addDefaultActionWithTitle(TrackingAction.trackShipment) { [weak self] _ in
                self?.openTrackingDetails(tracking)
            }
        }

        actionSheet.addDestructiveActionWithTitle(TrackingAction.deleteTracking) { [weak self] _ in
            WooAnalytics.shared.track(.orderDetailTrackingDeleteButtonTapped)
            self?.deleteTracking(tracking)
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = sourceView
        popoverController?.sourceRect = sourceView.bounds

        present(actionSheet, animated: true)
    }
}


// MARK: - Contact Alert
//
private extension OrderDetailsViewController {

    /// Displays an alert that offers several contact methods to reach the customer: [Phone / Message]
    ///
    func displayContactCustomerAlert(from sourceView: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = StyleManager.wooCommerceBrandColor

        actionSheet.addCancelActionWithTitle(ContactAction.dismiss)
        actionSheet.addDefaultActionWithTitle(ContactAction.call) { [weak self] _ in
            guard let phoneURL = self?.viewModel.order.billingAddress?.cleanedPhoneNumberAsActionableURL else {
                return
            }

            WooAnalytics.shared.track(.orderDetailCustomerPhoneOptionTapped)
            self?.callCustomerIfPossible(at: phoneURL)
        }

        actionSheet.addDefaultActionWithTitle(ContactAction.message) { [weak self] _ in
            WooAnalytics.shared.track(.orderDetailCustomerSMSOptionTapped)
            self?.displayMessageComposerIfPossible()
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = sourceView
        popoverController?.sourceRect = sourceView.bounds

        present(actionSheet, animated: true)

        WooAnalytics.shared.track(.orderDetailCustomerPhoneMenuTapped)
    }

    /// Attempts to perform a phone call at the specified URL
    ///
    func callCustomerIfPossible(at phoneURL: URL) {
        guard UIApplication.shared.canOpenURL(phoneURL) else {
            return
        }

        UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
        WooAnalytics.shared.track(.orderContactAction, withProperties: ["id": self.viewModel.order.orderID,
                                                                        "status": self.viewModel.order.statusKey,
                                                                        "type": "call"])

    }
}


// MARK: - Present Order Status List
//
private extension OrderDetailsViewController {
    private func displayOrderStatusList() {
        WooAnalytics.shared.track(.orderDetailOrderStatusEditButtonTapped,
                                  withProperties: ["status": viewModel.order.statusKey])
        let statusList = OrderStatusListViewController(order: viewModel.order)
        let navigationController = UINavigationController(rootViewController: statusList)

        present(navigationController, animated: true)
    }
}


// MARK: - MFMessageComposeViewControllerDelegate Conformance
//
extension OrderDetailsViewController: MFMessageComposeViewControllerDelegate {
    func displayMessageComposerIfPossible() {
        guard let phoneNumber = viewModel.order.billingAddress?.cleanedPhoneNumber,
            MFMessageComposeViewController.canSendText()
            else {
                return
        }

        displayMessageComposer(for: phoneNumber)
        WooAnalytics.shared.track(.orderContactAction, withProperties: ["id": viewModel.order.orderID,
                                                                        "status": viewModel.order.statusKey,
                                                                        "type": "sms"])
    }

    private func displayMessageComposer(for phoneNumber: String) {
        let controller = MFMessageComposeViewController()
        controller.recipients = [phoneNumber]
        controller.messageComposeDelegate = self
        present(controller, animated: true, completion: nil)
    }

    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        dismiss(animated: true, completion: nil)
    }
}


// MARK: - MFMailComposeViewControllerDelegate Conformance
//
extension OrderDetailsViewController: MFMailComposeViewControllerDelegate {
    func displayEmailComposerIfPossible() {
        guard let email = viewModel.order.billingAddress?.email, MFMailComposeViewController.canSendMail() else {
            return
        }

        displayEmailComposer(for: email)
        WooAnalytics.shared.track(.orderContactAction, withProperties: ["id": viewModel.order.orderID,
                                                                        "status": viewModel.order.statusKey,
                                                                        "type": "email"])
    }

    private func displayEmailComposer(for email: String) {
        // Workaround: MFMailCompose isn't *FULLY* picking up UINavigationBar's WC's appearance. Title / Buttons look awful.
        // We're falling back to iOS's default appearance
        UINavigationBar.applyDefaultAppearance()

        // Composer
        let controller = MFMailComposeViewController()
        controller.setToRecipients([email])
        controller.mailComposeDelegate = self
        present(controller, animated: true, completion: nil)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)

        // Workaround: Restore WC's navBar appearance
        UINavigationBar.applyWooAppearance()
    }
}


// MARK: - Error notice
private extension OrderDetailsViewController {
    /// Displays the `Unable to delete tracking` Notice.
    ///
    func displayDeleteErrorNotice(orderID: Int, tracking: ShipmentTracking) {
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

        AppDelegate.shared.noticePresenter.enqueue(notice: notice)
    }
}


// MARK: - Constants
//
private extension OrderDetailsViewController {

    enum ContactAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the action sheet")
        static let call = NSLocalizedString("Call", comment: "Call phone number button title")
        static let message = NSLocalizedString("Message", comment: "Message phone number button title")
    }

    enum TrackingAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the shipment tracking action sheet")
        static let trackShipment = NSLocalizedString("Track Shipment", comment: "Track shipment button title")
        static let deleteTracking = NSLocalizedString("Delete Tracking", comment: "Delete tracking button title")
    }

    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
        static let productDetailsSegue = "ShowProductListViewController"
        static let orderStatusListSegue = "ShowOrderStatusListViewController"
    }

    enum Title {
        static let product = NSLocalizedString("Product", comment: "Product section title")
        static let quantity = NSLocalizedString("Qty", comment: "Quantity abbreviation for section title")
        static let tracking = NSLocalizedString("Tracking", comment: "Order tracking section title")
        static let customerNote = NSLocalizedString("Customer Provided Note", comment: "Customer note section title")
        static let information = NSLocalizedString("Customer Information", comment: "Customer info section title")
        static let payment = NSLocalizedString("Payment", comment: "Payment section title")
        static let notes = NSLocalizedString("Order Notes", comment: "Order notes section title")
    }

    enum Footer {
        static let hideBilling = NSLocalizedString("Hide billing", comment: "Footer text to hide the billing cell")
        static let showBilling = NSLocalizedString("Show billing", comment: "Footer text to show the billing cell")
    }

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

    enum Row {
        case summary
        case fulfillButton
        case orderItem
        case details
        case tracking
        case trackingAdd
        case customerNote
        case shippingAddress
        case billingAddress
        case billingPhone
        case billingEmail
        case addOrderNote
        case orderNote
        case payment

        var reuseIdentifier: String {
            switch self {
            case .summary:
                return SummaryTableViewCell.reuseIdentifier
            case .fulfillButton:
                return FulfillButtonTableViewCell.reuseIdentifier
            case .orderItem:
                return ProductDetailsTableViewCell.reuseIdentifier
            case .details:
                return WooBasicTableViewCell.reuseIdentifier
            case .tracking:
                return OrderTrackingTableViewCell.reuseIdentifier
            case .trackingAdd:
                return LeftImageTableViewCell.reuseIdentifier
            case .customerNote:
                return CustomerNoteTableViewCell.reuseIdentifier
            case .shippingAddress:
                return CustomerInfoTableViewCell.reuseIdentifier
            case .billingAddress:
                return CustomerInfoTableViewCell.reuseIdentifier
            case .billingPhone:
                return WooBasicTableViewCell.reuseIdentifier
            case .billingEmail:
                return WooBasicTableViewCell.reuseIdentifier
            case .addOrderNote:
                return LeftImageTableViewCell.reuseIdentifier
            case .orderNote:
                return OrderNoteTableViewCell.reuseIdentifier
            case .payment:
                return PaymentTableViewCell.reuseIdentifier
            }
        }
    }
}
