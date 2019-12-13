import UIKit
import Yosemite


/// Renders the Order Billing Information Interface
///
final class BillingInformationViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Sections to be Rendered
    ///
    private var sections = [Section]()

    /// Order to be Fulfilled
    ///
    private let order: Order


    /// Designated Initializer
    ///
    init(order: Order) {
        self.order = order
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
        reloadSections()
    }

    /// Helpers
    ///
    private let emailComposer = OrderEmailComposer()

    private let messageComposer = OrderMessageComposer()

    /// Haptic Feedback!
    ///
    private let hapticGenerator = UINotificationFeedbackGenerator()
}

// MARK: - Interface Initialization
//
private extension BillingInformationViewController {

    /// Setup: Navigation Item
    ///
    func setupNavigationItem() {
        title = NSLocalizedString("Billing Information", comment: "Billing Information view Title")
    }

    /// Setup: Main View
    ///
    func setupMainView() {
        view.backgroundColor = .listBackground
        tableView.backgroundColor = .listBackground
        tableView.estimatedSectionHeaderHeight = Constants.sectionHeight
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
    }

    /// Registers all of the available TableViewCells
    ///
    func registerTableViewCells() {
        let cells = [
            BillingAddressTableViewCell.self,
            WooBasicTableViewCell.self
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

// MARK: - Initiate communication with a customer (i.e. via email, phone call, sms)
//
private extension BillingInformationViewController {
    func displayEmailComposerIfPossible(from: UIViewController) -> Bool {
        return emailComposer.displayEmailComposerIfPossible(for: order, from: from)
    }

    /// Displays an alert that offers several contact methods to reach the customer: [Phone / Message]
    ///
    func displayContactCustomerAlert(from: UIViewController) {
        guard let sourceView = from.view else {
            return
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addCancelActionWithTitle(ContactAction.dismiss)
        actionSheet.addDefaultActionWithTitle(ContactAction.call) { [weak self] _ in
            guard let self = self else {
                return
            }

            guard let phoneURL = self.order.billingAddress?.cleanedPhoneNumberAsActionableURL else {
                return
            }

            ServiceLocator.analytics.track(.orderDetailCustomerPhoneOptionTapped)
            self.callCustomerIfPossible(at: phoneURL)
        }

        actionSheet.addDefaultActionWithTitle(ContactAction.message) { [weak self] _ in
            ServiceLocator.analytics.track(.orderDetailCustomerSMSOptionTapped)
            self?.displayMessageComposerIfPossible(from: from)
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = sourceView
        popoverController?.sourceRect = sourceView.bounds

        from.present(actionSheet, animated: true)

        ServiceLocator.analytics.track(.orderDetailCustomerPhoneMenuTapped)
    }

    /// Attempts to perform a phone call at the specified URL
    ///
    func callCustomerIfPossible(at phoneURL: URL) {
        guard UIApplication.shared.canOpenURL(phoneURL) else {
            return
        }

        UIApplication.shared.open(phoneURL, options: [:], completionHandler: nil)
        ServiceLocator.analytics.track(.orderContactAction, withProperties: ["id": order.orderID,
                                                                        "status": order.statusKey,
                                                                        "type": "call"])

    }

    /// Initiate communication with a customer via message
    ///
    func displayMessageComposerIfPossible(from: UIViewController) {
        messageComposer.displayMessageComposerIfPossible(order: order, from: from)
    }

    /// Create an action sheet that offers the option to copy the email address
    ///
    func displayEmailCopyAlert(from: UIViewController) {
        guard let sourceView = from.view, let email = order.billingAddress?.email else {
            return
        }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addCancelActionWithTitle(ContactAction.dismiss)
        actionSheet.addDefaultActionWithTitle(ContactAction.copyEmail) { [weak self] _ in
            ServiceLocator.analytics.track(.orderDetailCustomerEmailTapped)
            self?.sendToPasteboard(email, includeTrailingNewline: false)
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = sourceView
        popoverController?.sourceRect = sourceView.bounds

        from.present(actionSheet, animated: true)

        ServiceLocator.analytics.track(.orderDetailCustomerEmailMenuTapped)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension BillingInformationViewController: UITableViewDataSource {

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
}

// MARK: - UITableViewDelegate Conformance
//
extension BillingInformationViewController: UITableViewDelegate {

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
        headerView.rightText = sections[section].secondaryTitle

        return headerView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section headers.
        return .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        tableView.deselectRow(at: indexPath, animated: true)

        switch sections[indexPath.section].rows[indexPath.row] {
        case .billingPhone:
            displayContactCustomerAlert(from: self)
            break

        case .billingEmail:
            ServiceLocator.analytics.track(.orderDetailCustomerEmailTapped)
            guard displayEmailComposerIfPossible(from: self) else {
                displayEmailCopyAlert(from: self)
                return
            }

            break
        default:
            break
        }
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

// MARK: - Cell Configuration
//
private extension BillingInformationViewController {

    /// Setup a given UITableViewCell instance to actually display the specified Row's Payload.
    ///
    func setup(cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BillingAddressTableViewCell where row == .billingAddress:
            setupBillingAddress(cell: cell)
        case let cell as WooBasicTableViewCell where row == .billingPhone:
            setupBillingPhone(cell: cell)
        case let cell as WooBasicTableViewCell where row == .billingEmail:
            setupBillingEmail(cell: cell)
        default:
            fatalError("Unidentified customer info row type")
        }
    }

    /// Setup: Billing Address Cell
    ///
    func setupBillingAddress(cell: BillingAddressTableViewCell) {
        let billingAddress = order.billingAddress

        cell.name = billingAddress?.fullNameWithCompany
        cell.address = billingAddress?.formattedPostalAddress ??
            NSLocalizedString("No address specified.",
                              comment: "Order details > customer info > billing information. This is where the address would normally display.")
    }

    func setupBillingPhone(cell: WooBasicTableViewCell) {
        guard let phoneNumber = order.billingAddress?.phone else {
            return
        }

        cell.bodyLabel?.text = phoneNumber
        cell.bodyLabel?.applyBodyStyle()
        cell.accessoryImage = .ellipsisImage

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
            comment: "VoiceOver accessibility hint, informing the user that the row can be tapped to call or message the billing customer."
        )
    }

    func setupBillingEmail(cell: WooBasicTableViewCell) {
        guard let email = order.billingAddress?.email else {
            return
        }

        cell.bodyLabel?.text = email
        cell.bodyLabel?.applyBodyStyle()
        cell.accessoryImage = .mailImage

        cell.isAccessibilityElement = true
        cell.accessibilityTraits = .button
        cell.accessibilityLabel = String.localizedStringWithFormat(
            NSLocalizedString("Email: %@",
                              comment: "Accessibility label that lets the user know the billing customer's email address"),
            email
        )

        cell.accessibilityHint = NSLocalizedString(
            "Composes a new email message to the billing customer.",
            comment: "Accessibility hint, informing that a row can be tapped and an email composer view will appear."
        )
    }
}

// MARK: - Table view sections
//
private extension BillingInformationViewController {
    func reloadSections() {
        let billingAddress: Section = {
            let title = NSLocalizedString("Billing Address", comment: "Section header title for billing address in billing information")
            return Section(title: title, secondaryTitle: nil, rows: [.billingAddress])
        }()

        let contactDetails: Section? = {
            guard let address = order.billingAddress else {
                return nil
            }

            var rows: [Row] = []

            if address.hasPhoneNumber {
                rows.append(.billingPhone)
            }
            if address.hasEmailAddress {
                rows.append(.billingEmail)
            }

            let title = NSLocalizedString("Contact Details", comment: "Section header title for contact details in billing information")
            return Section(title: title, secondaryTitle: nil, rows: rows)
        }()

        sections =  [billingAddress, contactDetails].compactMap { $0 }
    }
}

// MARK: - Pasteboard
//
private extension BillingInformationViewController {

    /// Sends the provided Row's text data to the pasteboard
    ///
    /// - Parameter indexPath: IndexPath to copy text data from
    ///
    func copyText(at indexPath: IndexPath) {
        let row = sections[indexPath.section].rows[indexPath.row]

        switch row {
        case .billingAddress:
            sendToPasteboard(order.billingAddress?.fullNameWithCompanyAndAddress)
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

    /// Checks if copying the row data at the provided indexPath is allowed
    ///
    /// - Parameter indexPath: index path of the row to check
    /// - Returns: true is copying is allowed, false otherwise
    ///
    func checkIfCopyingIsAllowed(for indexPath: IndexPath) -> Bool {
        let row = sections[indexPath.section].rows[indexPath.row]
        switch row {
        case .billingAddress:
            if let _ = order.billingAddress {
                return true
            }
        default:
            break
        }

        return false
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

// MARK: - Row: Represents a TableView Row
//
private enum Row {

    /// Represents an address row
    ///
    case billingAddress

    /// Represents a phone row
    ///
    case billingPhone

    /// Represents an email row
    ///
    case billingEmail

    /// Returns the Row's Reuse Identifier
    ///
    var reuseIdentifier: String {
        return cellType.reuseIdentifier
    }

    /// Returns the Row's Cell Type
    ///
    var cellType: UITableViewCell.Type {
        switch self {
        case .billingAddress:
            return BillingAddressTableViewCell.self
        case .billingPhone:
            return WooBasicTableViewCell.self
        case .billingEmail:
            return WooBasicTableViewCell.self
        }
    }
}

// MARK: - Constants
//
private extension BillingInformationViewController {
    enum ContactAction {
        static let dismiss = NSLocalizedString("Dismiss", comment: "Dismiss the action sheet")
        static let call = NSLocalizedString("Call", comment: "Call phone number button title")
        static let message = NSLocalizedString("Message", comment: "Message phone number button title")
        static let copyEmail = NSLocalizedString("Copy email address", comment: "Copy email address button title")
    }

    enum Constants {
        static let rowHeight = CGFloat(38)
        static let sectionHeight = CGFloat(44)
        static let footerHeight = CGFloat(0)
    }
}
