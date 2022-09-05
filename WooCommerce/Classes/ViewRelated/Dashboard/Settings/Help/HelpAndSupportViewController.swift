import UIKit
import Yosemite

// MARK: - HelpAndSupportViewController
//
final class HelpAndSupportViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet private weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    /// User's preferred email for support messages
    ///
    private var accountEmail: String {
        // A stored Zendesk email address is preferred
        if let zendeskEmail = ZendeskProvider.shared.userSupportEmail() {
            return zendeskEmail
        }

        // If no preferred ZD email exists, try the account email
        if let mainEmail = ServiceLocator.stores.sessionManager.defaultAccount?.email {
            return mainEmail
        }

        // If that doesn't exist, indicate we need them to set an email.
        return NSLocalizedString("Set email", comment: "Tells user to set an email that support can use for replies")
    }

    /// Payment Gateway Accounts Results Controller: Loads Payment Gateway Accounts from the Storage Layer
    /// e.g. WooCommerce Payments, but eventually other in-person payment accounts too
    ///
    private var paymentGatewayAccountsResultsController: ResultsController<StoragePaymentGatewayAccount>? = {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return nil
        }

        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "siteID == %lld", siteID)

        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [])
    }()

    private var isPaymentsAvailable: Bool {
        guard let accounts = paymentGatewayAccountsResultsController?.fetchedObjects else {
            return false
        }

        return accounts.contains(where: \.isCardPresentEligible)
    }

    /// Indicates if the NavBar should display a dismiss button
    ///
    var displaysDismissAction = false

    /// Custom help center web page related properties
    /// If non-nil this web page is launched instead of Zendesk
    ///
    private let customHelpCenterContent: CustomHelpCenterContent?

    init?(customHelpCenterContent: CustomHelpCenterContent, coder: NSCoder) {
        self.customHelpCenterContent = customHelpCenterContent
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        self.customHelpCenterContent = nil
        super.init(coder: coder)
    }

    // MARK: - Overridden Methods
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureSections()
        configureTableView()
        registerTableViewCells()
        configureResultsControllers { [weak self] in
            self?.refreshViewContent()
        }
        warnDeveloperIfNeeded()
        refreshViewContent()
    }
}

// MARK: - View Configuration
//
private extension HelpAndSupportViewController {

    /// Set the title and back button.
    ///
    func configureNavigation() {
        title = NSLocalizedString("Help", comment: "Help and Support navigation title")

        // Dismiss
        navigationItem.leftBarButtonItem = {
            guard displaysDismissAction else {
                return nil
            }

            let title = NSLocalizedString("Dismiss", comment: "Add a note screen - button title for closing the view")
            return UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(dismissWasPressed))
        }()
    }

    /// Apply Woo styles.
    ///
    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    /// Configure common table properties.
    ///
    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
    }

    func configureResultsControllers(onReload: @escaping () -> Void) {
        guard paymentGatewayAccountsResultsController != nil else {
            return
        }

        paymentGatewayAccountsResultsController?.onDidChangeContent = {
            onReload()
        }

        paymentGatewayAccountsResultsController?.onDidResetContent = {
            onReload()
        }

        try? paymentGatewayAccountsResultsController?.performFetch()
    }

    /// Disable Zendesk if configuration on ZD init fails.
    ///
    func configureSections() {
        let helpAndSupportTitle = NSLocalizedString("HOW CAN WE HELP?", comment: "My Store > Settings > Help & Support section title")
        #if !targetEnvironment(macCatalyst)
        guard ZendeskProvider.shared.zendeskEnabled == true else {
            sections = [Section(title: helpAndSupportTitle, rows: [.helpCenter])]
            return
        }

        sections = [
            Section(title: helpAndSupportTitle, rows: calculateRows())
        ]
        #else
        sections = [Section(title: helpAndSupportTitle, rows: [.helpCenter])]
        #endif
    }

    private func calculateRows() -> [Row] {
        var rows: [Row] = [.helpCenter, .contactSupport]
        if isPaymentsAvailable {
            rows.append(.contactWCPaySupport)
        }

        rows.append(contentsOf: [.myTickets,
                                 .contactEmail,
                                 .applicationLog,
                                 .systemStatusReport])
        return rows
    }

    /// Register table cells.
    ///
    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    /// Warn devs that logged in with an Automattic email.
    ///
    func warnDeveloperIfNeeded() {
        let developerEmailChecker = DeveloperEmailChecker()
        guard developerEmailChecker.isDeveloperEmail(email: accountEmail) else {
            return
        }

        let alert = UIAlertController(title: "Warning",
                                      message: "Developer email account detected. Please log in with a non-Automattic email to submit or view support tickets.",
                                      preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alert.addAction(cancel)

        present(alert, animated: true, completion: nil)
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as ValueOneTableViewCell where row == .helpCenter:
            configureHelpCenter(cell: cell)
        case let cell as ValueOneTableViewCell where row == .contactSupport:
            configureContactSupport(cell: cell)
        case let cell as ValueOneTableViewCell where row == .contactWCPaySupport:
            configureContactWCPaySupport(cell: cell)
        case let cell as ValueOneTableViewCell where row == .myTickets:
            configureMyTickets(cell: cell)
        case let cell as ValueOneTableViewCell where row == .contactEmail:
            configureMyContactEmail(cell: cell)
        case let cell as ValueOneTableViewCell where row == .applicationLog:
            configureApplicationLog(cell: cell)
        case let cell as ValueOneTableViewCell where row == .systemStatusReport:
            configureSystemStatusReport(cell: cell)
        default:
            fatalError()
        }
    }

    /// Help Center cell.
    ///
    func configureHelpCenter(cell: ValueOneTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Help Center", comment: "Browse our help documentation website title")
        cell.detailTextLabel?.text = NSLocalizedString("Get answers to questions you have", comment: "Subtitle for Help Center")
    }

    /// Contact Support cell.
    ///
    func configureContactSupport(cell: ValueOneTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Contact Support", comment: "Contact Support title")
        cell.detailTextLabel?.text = NSLocalizedString(
            "Reach our happiness engineers who can help answer tough questions",
            comment: "Subtitle for Contact Support"
        )
    }

    /// Contact WCPay Support cell.
    ///
    func configureContactWCPaySupport(cell: ValueOneTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Contact WooCommerce Payments Support", comment: "Contact WooComerce Payments Support title")
        cell.detailTextLabel?.text = NSLocalizedString(
            "Reach our happiness engineers who can help answer payments related questions",
            comment: "Subtitle for Contact WooCommerce Payments Support"
        )
    }

    /// My Tickets cell.
    ///
    func configureMyTickets(cell: ValueOneTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("My Tickets", comment: "My Tickets title")
        cell.detailTextLabel?.text = NSLocalizedString("View previously submitted support tickets", comment: "subtitle for My Tickets")
    }

    /// Contact Email cell.
    ///
    func configureMyContactEmail(cell: ValueOneTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Contact Email", comment: "Contact Email title")
        cell.detailTextLabel?.text = accountEmail
    }

    /// Application Log cell.
    ///
    func configureApplicationLog(cell: ValueOneTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("View Application Log", comment: "View application log cell title")
        cell.detailTextLabel?.text = NSLocalizedString(
            "Advanced tool to review the app status",
            comment: "Cell subtitle explaining why you might want to navigate to view the application log."
        )
    }

    /// System Status Report cell
    ///
    func configureSystemStatusReport(cell: ValueOneTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("System Status Report", comment: "View system status report cell title on Help screen")
        cell.detailTextLabel?.text = NSLocalizedString(
            "Various system information about your site",
            comment: "Description of the system status report on Help screen"
        )
    }

    func refreshViewContent() {
        configureSections()
        tableView.reloadData()
    }
}


// MARK: - Convenience Methods
//
private extension HelpAndSupportViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    /// Opens custom help center URL in a web view
    ///
    func launchCustomHelpCenterWebPage(_ customHelpCenterContent: CustomHelpCenterContent) {
        WebviewHelper.launch(customHelpCenterContent.url, with: self)

        ServiceLocator.analytics.track(.supportHelpCenterViewed,
                                       withProperties: customHelpCenterContent.trackingProperties)
    }
}

// MARK: - Actions
//
private extension HelpAndSupportViewController {

    /// Help Center action
    ///
    func helpCenterWasPressed() {
        if let customHelpCenterContent = customHelpCenterContent {
            launchCustomHelpCenterWebPage(customHelpCenterContent)
        } else {
            ZendeskProvider.shared.showHelpCenter(from: self)
        }
    }

    /// Contact Support action
    ///
    func contactSupportWasPressed() {
        guard let navController = navigationController else {
            return
        }

        ZendeskProvider.shared.showNewRequestIfPossible(from: navController)
    }

    /// Contact WCPay Support action
    ///
    func contactWCPaySupportWasPressed() {
        guard let navController = navigationController else {
            return
        }

        ZendeskProvider.shared.showNewWCPayRequestIfPossible(from: navController)
    }

    /// My Tickets action
    ///
    func myTicketsWasPressed() {
        guard let navController = navigationController else {
            return
        }

        ZendeskProvider.shared.showTicketListIfPossible(from: navController)
    }

    /// User's contact email action
    ///
    func contactEmailWasPressed() {
        guard let navController = navigationController else {
            return
        }

        ZendeskProvider.shared.showSupportEmailPrompt(from: navController) { [weak self] (success, email) in
            guard success else {
                return
            }

            guard let self = self else {
                return
            }

            self.warnDeveloperIfNeeded()

            // Tracking when the dialog's "OK" button is pressed, not necessarily if the value changed.
            ServiceLocator.analytics.track(.supportIdentitySet)
            self.tableView.reloadData()
        }
    }

    /// View application log action
    ///
    func applicationLogWasPressed() {
        let identifier = ApplicationLogViewController.classNameWithoutNamespaces
        guard let applicationLogVC = UIStoryboard.dashboard.instantiateViewController(identifier: identifier) as? ApplicationLogViewController else {
            DDLogError("Error: attempted to instantiate ApplicationLogViewController. Instantiation failed.")
            return
        }
        navigationController?.pushViewController(applicationLogVC, animated: true)
    }

    /// System status report action
    ///
    func systemStatusReportWasPressed() {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }
        let controller = SystemStatusReportHostingController(siteID: siteID)
        controller.hidesBottomBarWhenPushed = true
        controller.setDismissAction { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        navigationController?.pushViewController(controller, animated: true)
        ServiceLocator.analytics.track(.supportSSROpened)
    }

    @objc func dismissWasPressed() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource Conformance
//
extension HelpAndSupportViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section].title
    }
}

// MARK: - UITableViewDelegate Conformance
//
extension HelpAndSupportViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rowAtIndexPath(indexPath) {
        case .helpCenter:
            helpCenterWasPressed()
        case .contactSupport:
            contactSupportWasPressed()
        case .contactWCPaySupport:
            contactWCPaySupportWasPressed()
        case .myTickets:
            myTicketsWasPressed()
        case .contactEmail:
            contactEmailWasPressed()
        case .applicationLog:
            applicationLogWasPressed()
        case .systemStatusReport:
            systemStatusReportWasPressed()
        }
    }
}


// MARK: - Private Types
//
private struct Constants {
    static let rowHeight = CGFloat(44)
    static let footerHeight = 44
}

private struct Section {
    let title: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case helpCenter
    case contactSupport
    case contactWCPaySupport
    case myTickets
    case contactEmail
    case applicationLog
    case systemStatusReport

    var type: UITableViewCell.Type {
        switch self {
        case .helpCenter:
            return ValueOneTableViewCell.self
        case .contactSupport:
            return ValueOneTableViewCell.self
        case .contactWCPaySupport:
            return ValueOneTableViewCell.self
        case .myTickets:
            return ValueOneTableViewCell.self
        case .contactEmail:
            return ValueOneTableViewCell.self
        case .applicationLog:
            return ValueOneTableViewCell.self
        case .systemStatusReport:
            return ValueOneTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}
