import UIKit
import Gridicons
import Contacts
import MessageUI
import Yosemite
import CocoaLumberjack


class OrderDetailsViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet weak var tableView: UITableView!
    var viewModel: OrderDetailsViewModel! {
        didSet {
            reloadSections()
            reloadTableViewIfPossible()
        }
    }

    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        return refreshControl
    }()

    private var orderNotes: [OrderNoteViewModel] = [] {
        didSet {
            reloadSections()
            reloadTableViewIfPossible()
        }
    }

    private var displaysBillingDetails = false {
        didSet {
            reloadSections()
        }
    }
    private var sections = [Section]()

    /// EntityListener: Update / Deletion Notifications.
    ///
    private lazy var entityListener: EntityListener<Order> = {
        return EntityListener(storageManager: AppDelegate.shared.storageManager, readOnlyEntity: viewModel.order)
    }()



    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
        configureEntityListener()
        registerTableViewCells()
        registerTableViewHeaderFooters()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncNotes()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
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
            self.viewModel = OrderDetailsViewModel(order: order)
        }

        entityListener.onDelete = { [weak self] in
            guard let `self` = self else {
                return
            }

            self.navigationController?.popViewController(animated: true)
            self.displayOrderDeletedNotice()
        }
    }

    /// Reloads the tableView, granted that the view has been effectively loaded.
    ///
    func reloadTableViewIfPossible() {
        guard isViewLoaded else {
            return
        }

        tableView.reloadData()
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

        sections = [summary, products, customerNote, customerInformation, payment, notes].compactMap { $0 }
    }
}


// MARK: - Notices
//
private extension OrderDetailsViewController {

    /// Displays a Notice onscreen, indicating that the current Order has been deleted from the Store.
    ///
    func displayOrderDeletedNotice() {
        let title = NSLocalizedString("Deleted: Order #\(viewModel.order.number)", comment: "Order Notice")
        let message = NSLocalizedString("The order has been deleted from your Store!",
                                        comment: "Displayed whenever the Details for an Order that just got deleted was onscreen.")

        let notice = Notice(title: title, message: message, feedbackType: .error)
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
            cell.configure(with: viewModel)
        case let cell as LeftImageTableViewCell:
            configureNewNote(cell: cell)
        case let cell as OrderNoteTableViewCell:
            if let note = note(at: indexPath) {
                cell.configure(with: note)
            }
        case let cell as PaymentTableViewCell:
            cell.configure(with: viewModel)
        case let cell as ProductListTableViewCell:
            cell.configure(with: viewModel)
            cell.onFullfillTouchUp = { [weak self] in
                self?.fulfillWasPressed()
            }
        case let cell as SummaryTableViewCell:
            configureSummaryTableView(cell: cell)
        default:
            fatalError("Unidentified customer info row type")
        }
    }

    /// Cell configuration methods
    ///
    func configureBillingAddress(cell: CustomerInfoTableViewCell) {
        let billingAddress = viewModel.order.billingAddress

        cell.title = NSLocalizedString("Billing details", comment: "Billing title for customer info cell")
        cell.name = billingAddress?.fullName
        cell.address = billingAddress?.formattedPostalAddress ?? NSLocalizedString("No address specified.", comment: "Order details > customer info > billing details. This is where the address would normally display.")
    }

    func configureBillingEmail(cell: BillingDetailsTableViewCell) {
        guard let email = viewModel.order.billingAddress?.email else {
            // TODO: This should actually be an assert. To be revisited!
            return
        }

        cell.configure(text: email, image: Gridicon.iconOfType(.mail))
        cell.onTouchUp = { [weak self] in
            self?.emailButtonAction()
        }

        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("Email: %@", comment: "Accessibility label that lets the user know the billing customer's email address"), email)
        cell.accessibilityHint = NSLocalizedString("Composes a new email message to the billing customer.", comment: "VoiceOver accessibility hint, informing the user that the row can be tapped and an email composer view will appear.")
    }

    func configureBillingPhone(cell: BillingDetailsTableViewCell) {
        guard let phoneNumber = viewModel.order.billingAddress?.phone else {
            // TODO: This should actually be an assert. To be revisited!
            return
        }

        cell.configure(text: phoneNumber, image: Gridicon.iconOfType(.ellipsis))
        cell.onTouchUp = { [weak self] in
            self?.phoneButtonAction()
        }

        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("Phone number: %@", comment: "Accessibility label that lets the user know the data is a phone number before speaking the phone number."), phoneNumber)
        cell.accessibilityHint = NSLocalizedString("Prompts with the option to call or message the billing customer.", comment: "VoiceOver accessibility hint, informing the user that the row can be tapped to get to a prompt that lets them call or message the billing customer.")
    }

    func configureNewNote(cell: LeftImageTableViewCell) {
        cell.leftImage = viewModel.addNoteIcon
        cell.labelText = viewModel.addNoteText

        cell.accessibilityTraits = .button
        cell.accessibilityLabel = NSLocalizedString("Add a note button", comment: "Accessibility label for the 'Add a note' button")
        cell.accessibilityHint = NSLocalizedString("Composes a new order note.", comment: "VoiceOver accessibility hint, informing the user that the button can be used to create a new order note.")
    }

    func configureProductDetails(cell: BasicTableViewCell) {
        cell.configure(text: viewModel.productDetails)
        cell.accessoryType = .disclosureIndicator
    }

    func configureShippingAddress(cell: CustomerInfoTableViewCell) {
        let shippingAddress = viewModel.order.shippingAddress

        cell.title = NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
        cell.name = shippingAddress?.fullName
        cell.address = shippingAddress?.formattedPostalAddress ?? NSLocalizedString("No address specified.", comment: "Order details > customer info > shipping details. This is where the address would normally display.")
    }

    func configureSummaryTableView(cell: SummaryTableViewCell) {
        cell.configure(with: viewModel)
    }

    // MARK: - Get order note
    //
    func note(at indexPath: IndexPath) -> OrderNoteViewModel? {
        // We need to subtract 1 here because the first order note row is the "Add Order" cell
        let noteIndex = indexPath.row - 1
        guard orderNotes.indices.contains(noteIndex) else {
            return nil
        }

        return orderNotes[noteIndex]
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

            self.viewModel = OrderDetailsViewModel(order: order)
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

            self?.orderNotes = orderNotes.map { OrderNoteViewModel(with: $0) }
            WooAnalytics.shared.track(.orderNotesLoaded, withProperties: ["id": self?.viewModel.order.orderID ?? 0])
            onCompletion?(nil)
        }

        StoresManager.shared.dispatch(action)
    }
}


// MARK: - Actions
//
extension OrderDetailsViewController {
    @objc func phoneButtonAction() {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = StyleManager.wooCommerceBrandColor
        let dismissAction = UIAlertAction(title: NSLocalizedString("Dismiss", comment: "Dismiss the action sheet"), style: .cancel)
        actionSheet.addAction(dismissAction)

        let callAction = UIAlertAction(title: NSLocalizedString("Call", comment: "Call phone number button title"), style: .default) { [weak self] action in
            WooAnalytics.shared.track(.orderDetailCustomerPhoneOptionTapped)
            guard let phone = self?.viewModel.order.billingAddress?.cleanedPhoneNumber else {
                return
            }
            if let url = URL(string: "telprompt://" + phone),
                UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                WooAnalytics.shared.track(.orderContactAction, withProperties: ["id": self?.viewModel.order.orderID ?? 0,
                                                                                "status": self?.viewModel.order.status.rawValue ?? String(),
                                                                                "type": "call"])
            }
        }
        actionSheet.addAction(callAction)

        let messageAction = UIAlertAction(title: NSLocalizedString("Message", comment: "Message phone number button title"), style: .default) { [weak self] action in
            WooAnalytics.shared.track(.orderDetailCustomerSMSOptionTapped)
            self?.sendTextMessageIfPossible()
        }

        actionSheet.addAction(messageAction)
        WooAnalytics.shared.track(.orderDetailCustomerPhoneMenuTapped)
        present(actionSheet, animated: true)
    }

    @objc func emailButtonAction() {
        WooAnalytics.shared.track(.orderDetailCustomerEmailTapped)
        sendEmailIfPossible()
    }

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
            return CGFloat.leastNonzeroMagnitude
        }

        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let leftText = sections[section].title else {
            return nil
        }

        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TwoColumnSectionHeaderView.reuseIdentifier) as? TwoColumnSectionHeaderView else {
            fatalError()
        }

        headerView.leftText = leftText
        headerView.rightText = sections[section].rightTitle

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let _ = sections[section].footer else {
            // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section footers.
            return CGFloat.leastNonzeroMagnitude
        }

        return UITableView.automaticDimension
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
            let addANoteViewController = self.storyboard!.instantiateViewController(withIdentifier: Constants.noteViewController) as! AddANoteViewController
            addANoteViewController.viewModel = viewModel
            let navController = WooNavigationController(rootViewController: addANoteViewController)
            present(navController, animated: true, completion: nil)
        case .productDetails:
            WooAnalytics.shared.track(.orderDetailProductDetailTapped)
            performSegue(withIdentifier: Constants.productDetailsSegue, sender: nil)
        default:
            break
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let productListViewController = segue.destination as? ProductListViewController {
            productListViewController.viewModel = viewModel
        }
    }
}


// MARK: - MFMessageComposeViewControllerDelegate Conformance
//
extension OrderDetailsViewController: MFMessageComposeViewControllerDelegate {
    func sendTextMessageIfPossible() {
        guard let phoneNumber = viewModel.order.billingAddress?.cleanedPhoneNumber else {
            return
        }

        if MFMessageComposeViewController.canSendText() {
            sendTextMessage(to: phoneNumber)
            WooAnalytics.shared.track(.orderContactAction, withProperties: ["id": viewModel.order.orderID,
                                                                            "status": viewModel.order.status.rawValue,
                                                                            "type": "sms"])
        }
    }

    private func sendTextMessage(to phoneNumber: String) {
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
    func sendEmailIfPossible() {
        guard let email = viewModel.order.billingAddress?.email, MFMailComposeViewController.canSendMail() else {
            return
        }

        sendEmail(to: email)
        WooAnalytics.shared.track(.orderContactAction, withProperties: ["id": viewModel.order.orderID,
                                                                        "status": viewModel.order.status.rawValue,
                                                                        "type": "email"])
    }

    private func sendEmail(to email: String) {
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
    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
        static let productDetailsSegue = "ShowProductListViewController"
        static let noteViewController = "AddANoteViewController"
    }

    enum Title {
        static let product = NSLocalizedString("Product", comment: "Product section title")
        static let quantity = NSLocalizedString("Qty", comment: "Quantity abbreviation for section title")
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
