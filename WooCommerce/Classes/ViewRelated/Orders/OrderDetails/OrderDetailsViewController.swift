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

    private var billingIsHidden = true {
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
        syncOrderNotes()
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
        tableView.rowHeight = UITableViewAutomaticDimension
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

    /// Setup: Sections
    ///
    func reloadSections() {
        let summary = Section(row: .summary)

        let products: Section = {
            let rows: [Row] = viewModel.isProcessingPayment ? [.productList] : [.productList, .productDetails]
            return Section(title: Title.product, rightTitle: Title.quantity, rows: rows)
        }()

        let customerNote: Section? = {
            guard viewModel.customerNote.isEmpty == false else {
                return nil
            }

            return Section(title: Title.customerNote, row: .customerNote)
        }()

        let info: Section = {
            let footer = billingIsHidden ? NSLocalizedString("Show billing", comment: "Footer text to show the billing cell") : NSLocalizedString("Hide billing", comment: "Footer text to hide the billing cell")
            let rows: [Row]

            if billingIsHidden {
                rows = [.shippingAddress]
            } else if viewModel.order.billingAddress == nil {
                rows = [.shippingAddress, .billingAddress]
            } else {
                rows = [.shippingAddress, .billingAddress, .billingPhone, .billingEmail]
            }

            return Section(title: Title.information, footer: footer, rows: rows)
        }()

        let payment = Section(title: Title.payment, row: .payment)

        let notes: Section = {
            let rows = [.addOrderNote] + Array(repeating: Row.orderNote, count: orderNotes.count)
            return Section(title: Title.notes, rows: rows)
        }()

        sections = [summary, products, customerNote, info, payment, notes].compactMap { $0 }
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
            BasicDisclosureTableViewCell.self,
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
        let group = DispatchGroup()

        group.enter()
        syncOrder { _ in
            group.leave()
        }

        group.enter()
        syncOrderNotes { _ in
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
    private func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as SummaryTableViewCell:
            cell.configure(with: viewModel)
        case let cell as ProductListTableViewCell:
            cell.configure(with: viewModel)
            cell.onFullfillTouchUp = { [weak self] in
                self?.fulfillWasPressed()
            }
        case let cell as BasicDisclosureTableViewCell:
            cell.configure(text: viewModel.productDetails)
        case let cell as CustomerNoteTableViewCell:
            cell.configure(with: viewModel)
        case let cell as CustomerInfoTableViewCell where row == .shippingAddress:
            if let shippingViewModel = viewModel.shippingViewModel {
                cell.title = shippingViewModel.title
                cell.name = shippingViewModel.fullName
                cell.address = shippingViewModel.formattedAddress
            } else {
                cell.title = NSLocalizedString("Shipping details", comment: "Shipping title for customer info cell")
                cell.name = nil
                cell.address = NSLocalizedString("No address specified.", comment: "Order details > customer info > shipping details. This is where the address would normally display.")
            }
        case let cell as CustomerInfoTableViewCell where row == .billingAddress:
            if let billingViewModel = viewModel.billingViewModel {
                cell.title = billingViewModel.title
                cell.name = billingViewModel.fullName
                cell.address = billingViewModel.formattedAddress
            } else {
                cell.title = NSLocalizedString("Billing details", comment: "Billing title for customer info cell")
                cell.name = nil
                cell.address = NSLocalizedString("No address specified.", comment: "Order details > customer info > billing details. This is where the address would normally display.")
            }
        case let cell as BillingDetailsTableViewCell where row == .billingPhone:
            configureBillingPhone(cell: cell)
        case let cell as BillingDetailsTableViewCell where row == .billingEmail:
            configureBillingEmail(cell: cell)
        case let cell as PaymentTableViewCell:
            cell.configure(with: viewModel)
        case let cell as LeftImageTableViewCell:
            cell.configure(image: viewModel.addNoteIcon, text: viewModel.addNoteText)
            cell.accessibilityTraits = UIAccessibilityTraitButton
            cell.accessibilityLabel = NSLocalizedString("Add a note button", comment: "Accessibility label for the 'Add a note' button")
            cell.accessibilityHint = NSLocalizedString("Composes a new order note.", comment: "VoiceOver accessibility hint, informing the user that the button can be used to create a new order note.")
        case let cell as OrderNoteTableViewCell where row == .orderNote:
            if let note = orderNote(at: indexPath) {
                cell.configure(with: note)
            }
        default:
            fatalError("Unidentified customer info row type")
        }
    }

    private func configureBillingPhone(cell: BillingDetailsTableViewCell) {
        cell.configure(text: viewModel.billingViewModel?.phoneNumber, image: Gridicon.iconOfType(.ellipsis))
        cell.onTouchUp = { [weak self] in
            self?.phoneButtonAction()
        }
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = UIAccessibilityTraitButton
        if let phoneNumber = viewModel.billingViewModel?.phoneNumber {
            cell.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("Phone number: %@", comment: "Accessibility label that lets the user know the data is a phone number before speaking the phone number."), phoneNumber)
        }
        cell.accessibilityHint = NSLocalizedString("Prompts with the option to call or message the billing customer.", comment: "VoiceOver accessibility hint, informing the user that the row can be tapped to get to a prompt that lets them call or message the billing customer.")
    }

    private func configureBillingEmail(cell: BillingDetailsTableViewCell) {
        cell.configure(text: viewModel.billingViewModel?.email, image: Gridicon.iconOfType(.mail))
        cell.onTouchUp = { [weak self] in
            self?.emailButtonAction()
        }
        cell.isAccessibilityElement = true
        cell.accessibilityTraits = UIAccessibilityTraitButton
        if let email = viewModel.billingViewModel?.email {
            cell.accessibilityLabel = String.localizedStringWithFormat(NSLocalizedString("Email: %@", comment: "Accessibility label that lets the user know the billing customer's email address"), email)
        }
        cell.accessibilityHint = NSLocalizedString("Composes a new email message to the billing customer.", comment: "VoiceOver accessibility hint, informing the user that the row can be tapped and an email composer view will appear.")
    }

    func orderNote(at indexPath: IndexPath) -> OrderNoteViewModel? {
        // We need to subract 1 here because the first order note row is the "Add Order" cell
        let orderNoteIndex = indexPath.row - 1
        guard !orderNotes.isEmpty, orderNotes.indices.contains(orderNoteIndex) else {
            return nil
        }

        return orderNotes[orderNoteIndex]
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

    func syncOrderNotes(onCompletion: ((Error?) -> ())? = nil) {
        let action = OrderNoteAction.retrieveOrderNotes(siteID: viewModel.order.siteID, orderID: viewModel.order.orderID) { [weak self] (orderNotes, error) in
            guard let orderNotes = orderNotes else {
                DDLogError("⛔️ Error synchronizing Order Notes: \(error.debugDescription)")
                self?.orderNotes = []
                onCompletion?(error)
                return
            }

            self?.orderNotes = orderNotes.map { OrderNoteViewModel(with: $0) }
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
            let contactViewModel = ContactViewModel(with: (self?.viewModel.order.billingAddress)!)
            guard let phone = contactViewModel.cleanedPhoneNumber else {
                return
            }
            if let url = URL(string: "telprompt://" + phone),
                UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        actionSheet.addAction(callAction)

        let messageAction = UIAlertAction(title: NSLocalizedString("Message", comment: "Message phone number button title"), style: .default) { [weak self] action in
            self?.sendTextMessageIfPossible()
        }
        actionSheet.addAction(messageAction)

        present(actionSheet, animated: true)
    }

    @objc func emailButtonAction() {
        sendEmailIfPossible()
    }

    func toggleBillingFooter() {
        billingIsHidden = !billingIsHidden
    }

    func fulfillWasPressed() {
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

        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let leftText = sections[section].title else {
            return nil
        }

        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: TwoColumnSectionHeaderView.reuseIdentifier) as? TwoColumnSectionHeaderView else {
            fatalError()
        }
        cell.configure(leftText: leftText, rightText: sections[section].rightTitle)

        return cell
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let _ = sections[section].footer else {
            // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section footers.
            return CGFloat.leastNonzeroMagnitude
        }

        return UITableViewAutomaticDimension
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footerText = sections[section].footer else {
            return nil
        }

        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: ShowHideSectionFooter.reuseIdentifier) as! ShowHideSectionFooter
        let image = billingIsHidden ? Gridicon.iconOfType(.chevronDown) : Gridicon.iconOfType(.chevronUp)
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

        if sections[indexPath.section].rows[indexPath.row] == .addOrderNote {
            let addANoteViewController = self.storyboard!.instantiateViewController(withIdentifier: Constants.noteViewController) as! AddANoteViewController
            addANoteViewController.viewModel = viewModel
            let navController = UINavigationController(rootViewController: addANoteViewController)
            present(navController, animated: true, completion: nil)
        } else if sections[indexPath.section].rows[indexPath.row] == .productDetails {
            performSegue(withIdentifier: Constants.productDetailsSegue, sender: nil)
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
        guard let billingAddress = viewModel.order.billingAddress else {
            return
        }

        let contactViewModel = ContactViewModel(with: billingAddress)
        guard let phoneNumber = contactViewModel.cleanedPhoneNumber else {
            return
        }
        if MFMessageComposeViewController.canSendText() {
            sendTextMessage(to: phoneNumber)
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
        if MFMailComposeViewController.canSendMail() {
            guard let billingAddress = viewModel.order.billingAddress else {
                return
            }

            let contactViewModel = ContactViewModel(with: billingAddress)
            guard let email = contactViewModel.email else {
                return
            }

            sendEmail(to: email)
        }
    }

    private func sendEmail(to email: String) {
        let controller = MFMailComposeViewController()
        controller.setToRecipients([email])
        controller.mailComposeDelegate = self
        present(controller, animated: true, completion: nil)
    }

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
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
        static let product = NSLocalizedString("PRODUCT", comment: "Product section title")
        static let quantity = NSLocalizedString("QTY", comment: "Quantity abbreviation for section title")
        static let customerNote = NSLocalizedString("CUSTOMER PROVIDED NOTE", comment: "Customer note section title")
        static let information = NSLocalizedString("CUSTOMER INFORMATION", comment: "Customer info section title")
        static let payment = NSLocalizedString("PAYMENT", comment: "Payment section title")
        static let notes = NSLocalizedString("ORDER NOTES", comment: "Order notes section title")
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
                return BasicDisclosureTableViewCell.reuseIdentifier
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
