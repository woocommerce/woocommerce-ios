import UIKit
import Gridicons
import Contacts
import MessageUI
import Yosemite
import SafariServices


// MARK: - OrderDetailsViewController: Displays the details for a given Order.
//
class OrderDetailsViewController: UIViewController {

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
        syncTracking()
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
            guard let `self` = self else {
                return
            }

            let orderStatus = self.lookUpOrderStatus(for: order)
            self.viewModel = OrderDetailsViewModel(order: order, orderStatus: orderStatus)
        }

        entityListener.onDelete = { [weak self] in
            guard let `self` = self else {
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
            BillingDetailsTableViewCell.self,
            CustomerNoteTableViewCell.self,
            CustomerInfoTableViewCell.self,
            BasicTableViewCell.self,
            OrderNoteTableViewCell.self,
            PaymentTableViewCell.self,
            ProductListTableViewCell.self,
            OrderTrackingTableViewCell.self,
            SummaryTableViewCell.self
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

            let rows: [Row] = viewModel.isProcessingPayment ? [.productList] : [.productList, .productDetails]
            return Section(title: Title.product, rightTitle: Title.quantity, rows: rows)
        }()

        let tracking: Section? = {
            guard orderTracking.count > 0 else {
                return nil
            }

            let rows: [Row] = Array(repeating: .tracking, count: orderTracking.count)
            return Section(title: Title.tracking, rows: rows)
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

        let notes: Section = {
            let rows = [.addOrderNote] + Array(repeating: Row.orderNote, count: orderNotes.count)
            return Section(title: Title.notes, rows: rows)
        }()

        sections = [summary, products, tracking, customerNote, customerInformation, payment, notes].compactMap { $0 }
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
                comment: """
                    Displayed whenever the Details for an Order that just got deleted was onscreen. \
                    It reads: Order {order number} has been deleted from your store
                    """
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
        case let cell as BasicTableViewCell:
            configureProductDetails(cell: cell)
        case let cell as BillingDetailsTableViewCell where row == .billingEmail:
            configureBillingEmail(cell: cell)
        case let cell as BillingDetailsTableViewCell where row == .billingPhone:
            configureBillingPhone(cell: cell)
        case let cell as CustomerInfoTableViewCell where row == .billingAddress:
            configureBillingAddress(cell: cell)
        case let cell as CustomerInfoTableViewCell where row == .shippingAddress:
            configureShippingAddress(cell: cell)
        case let cell as CustomerNoteTableViewCell:
            configureCustomerNote(cell: cell)
        case let cell as LeftImageTableViewCell:
            configureNewNote(cell: cell)
        case let cell as OrderNoteTableViewCell:
            configureOrderNote(cell: cell, at: indexPath)
        case let cell as PaymentTableViewCell:
            configurePayment(cell: cell)
        case let cell as ProductListTableViewCell:
            configureProductList(cell: cell)
        case let cell as OrderTrackingTableViewCell:
            configureTracking(cell: cell, at: indexPath)
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

    func configureBillingEmail(cell: BillingDetailsTableViewCell) {
        guard let email = viewModel.order.billingAddress?.email else {
            // TODO: This should actually be an assert. To be revisited!
            return
        }

        cell.textLabel?.text = email
        cell.accessoryImageView.image = Gridicon.iconOfType(.mail)
        cell.onTouchUp = { [weak self] _ in
            WooAnalytics.shared.track(.orderDetailCustomerEmailTapped)
            self?.displayEmailComposerIfPossible()
        }

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

    func configureBillingPhone(cell: BillingDetailsTableViewCell) {
        guard let phoneNumber = viewModel.order.billingAddress?.phone else {
            // TODO: This should actually be an assert. To be revisited!
            return
        }

        cell.textLabel?.text = phoneNumber
        cell.accessoryImageView.image = Gridicon.iconOfType(.ellipsis)
        cell.onTouchUp = { [weak self] sender in
            self?.displayContactCustomerAlert(from: sender)
        }

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
            comment: """
                VoiceOver accessibility hint, informing the user that the row can be tapped to get to a \
                prompt that lets them call or message the billing customer.
                """
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
        cell.dateCreated = note.dateCreated.toString(dateStyle: .medium, timeStyle: .short)
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

        cell.accessibilityElements = [cell.subtotalLabel,
                                      cell.subtotalValue,
                                      cell.discountLabel,
                                      cell.discountValue,
                                      cell.shippingLabel,
                                      cell.shippingValue,
                                      cell.taxesLabel,
                                      cell.taxesValue,
                                      cell.totalLabel,
                                      cell.totalValue]

        if let footerText = cell.footerText {
            cell.accessibilityElements?.append(footerText)
        }
    }

    func configureProductDetails(cell: BasicTableViewCell) {
        cell.textLabel?.text = viewModel.productDetails
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
    }

    func configureProductList(cell: ProductListTableViewCell) {
        for subView in cell.verticalStackView.arrangedSubviews {
            subView.removeFromSuperview()
        }

        for (index, item) in viewModel.items.enumerated() {
            let itemView = TwoColumnLabelView.makeFromNib()
            itemView.leftText = item.name
            itemView.rightText = item.quantity.description
            cell.verticalStackView.insertArrangedSubview(itemView, at: index)
        }

        cell.fulfillButton.setTitle(viewModel.fulfillTitle, for: .normal)
        cell.actionContainerView.isHidden = viewModel.isProcessingPayment == false

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

        guard let url = tracking.trackingURL, url.isEmpty == false else {
            cell.hideActionButton()
            return
        }

        cell.showActionButton()
        cell.actionButtonNormalText = viewModel.trackTitle

        cell.onActionTouchUp = { [ weak self ] in
            self?.trackingWasPressed(at: indexPath)
        }
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
            guard let `self` = self, let order = order else {
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
        guard let tracking = orderTracking(at: indexPath) else {
            return
        }

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
        if sections[section].title == nil {
            // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section headers.
            return .leastNonzeroMagnitude
        }

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
            guard let `self` = self else {
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
        case .productDetails:
            WooAnalytics.shared.track(.orderDetailProductDetailTapped)
            performSegue(withIdentifier: Constants.productDetailsSegue, sender: nil)
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard checkIfCopyingIsAllowed(for: indexPath) else {
            // Only allow the leading swipe action on the address rows
            return UISwipeActionsConfiguration(actions: [])
        }

        let row = rowAtIndexPath(indexPath)
        let copyActionTitle = NSLocalizedString("Copy", comment: "Copy address text button title — should be one word and as short as possible.")
        let copyAction = UIContextualAction(style: .normal, title: copyActionTitle) { [weak self] (action, view, success) in
            self?.copyText(at: row)
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

        let row = rowAtIndexPath(indexPath)
        copyText(at: row)
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
        default:
            break
        }

        return false
    }

    /// Sends the provided Row's text data to the pasteboard
    ///
    /// - Parameter row: Row to copy text data from
    ///
    func copyText(at row: Row) {
        switch row {
        case .billingAddress:
            sendToPasteboard(viewModel.order.billingAddress?.fullNameWithCompanyAndAddress)
        case .shippingAddress:
            sendToPasteboard(viewModel.order.shippingAddress?.fullNameWithCompanyAndAddress)
        default:
            break // We only send text to the pasteboard from the address rows right meow
        }
    }

    /// Sends the provided text to the general pasteboard and triggers a success haptic. If the text param
    /// is nil, nothing is sent to the pasteboard.
    ///
    /// - Parameter text: string value to send to the pasteboard
    ///
    func sendToPasteboard(_ text: String?) {
        guard let text = text, text.isEmpty == false else {
            return
        }

        // Insert an extra newline to make life easier when pasting
        UIPasteboard.general.string = text + "\n"
        hapticGenerator.notificationOccurred(.success)
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


// MARK: - Constants
//
private extension OrderDetailsViewController {

    enum ContactAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the action sheet")
        static let call = NSLocalizedString("Call", comment: "Call phone number button title")
        static let message = NSLocalizedString("Message", comment: "Message phone number button title")
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
        case productList
        case productDetails
        case tracking
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
            case .productList:
                return ProductListTableViewCell.reuseIdentifier
            case .productDetails:
                return BasicTableViewCell.reuseIdentifier
            case .tracking:
                return OrderTrackingTableViewCell.reuseIdentifier
            case .customerNote:
                return CustomerNoteTableViewCell.reuseIdentifier
            case .shippingAddress:
                return CustomerInfoTableViewCell.reuseIdentifier
            case .billingAddress:
                return CustomerInfoTableViewCell.reuseIdentifier
            case .billingPhone:
                return BillingDetailsTableViewCell.reuseIdentifier
            case .billingEmail:
                return BillingDetailsTableViewCell.reuseIdentifier
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
