import UIKit
import Yosemite


// MARK: - HelpAndSupportViewController
//
class HelpAndSupportViewController: UIViewController {
    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    /// User's preferred email for support messages
    ///
    private var accountEmail: String {
        return StoresManager.shared.sessionManager.defaultAccount?.email ?? NSLocalizedString("Set email", comment: "Tells user to set an email that support can use for replies")
    }


    // MARK: - Overridden Methods
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureSections()
        configureTableView()
        configureTableViewFooter()
        registerTableViewCells()
        warnDeveloperIfNeeded()
    }
}

// MARK: - View Configuration
//
private extension HelpAndSupportViewController {

    /// Set the title and back button.
    ///
    func configureNavigation() {
        title = NSLocalizedString("Help", comment: "Help and Support navigation title")
        // Don't show the Settings title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }

    /// Apply Woo styles.
    ///
    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Configure common table properties.
    ///
    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    /// Display the version number in the footer.
    ///
    func configureTableViewFooter() {
        let versionLabel = NSLocalizedString("Version", comment: "App version label")
        let appVersion = UserAgent.bundleShortVersion
        let versionSummary = versionLabel + " " + appVersion

        /// `tableView.tableFooterView` can't handle a footerView that uses autolayout only.
        /// Hence the container view with a defined frame.
        let footerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: Constants.footerHeight))
        let footerView = TableFooterView.instantiateFromNib() as TableFooterView
        footerView.footnoteText = versionSummary
        footerView.footnoteColor = StyleManager.wooGreyMid
        tableView.tableFooterView = footerContainer
        footerContainer.addSubview(footerView)
    }

    /// Disable Zendesk if configuration on ZD init fails.
    ///
    func configureSections() {
        let helpAndSupportTitle = NSLocalizedString("HOW CAN WE HELP?", comment: "My Store > Settings > Help & Support section title")

        guard ZendeskManager.shared.zendeskEnabled == true else {
            sections = [Section(title: helpAndSupportTitle, rows: [.browseFaq])]
            return
        }

        sections = [
            Section(title: helpAndSupportTitle, rows: [.browseFaq,
                                                       .contactSupport,
                                                       .myTickets,
                                                       .contactEmail])
        ]
    }

    /// Register table cells.
    ///
    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    /// Warn devs that logged in with an Automattic email.
    ///
    func warnDeveloperIfNeeded() {
        guard accountEmail.contains(Constants.devEmail) else {
            return
        }

        let alert = UIAlertController(title: "Warning", message: "Developer email account detected. Please log in with a non-Automattic email to submit or view support tickets.", preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alert.addAction(cancel)

        present(alert, animated: true, completion: nil)
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as ValueOneTableViewCell where row == .browseFaq:
            configureBrowseFaq(cell: cell)
        case let cell as ValueOneTableViewCell where row == .contactSupport:
            configureContactSupport(cell: cell)
        case let cell as ValueOneTableViewCell where row == .myTickets:
            configureMyTickets(cell: cell)
        case let cell as ValueOneTableViewCell where row == .contactEmail:
            configureMyContactEmail(cell: cell)
        default:
            fatalError()
        }
    }

    /// Browse our FAQ cell.
    ///
    func configureBrowseFaq(cell: ValueOneTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Browse our FAQ", comment: "Browse our FAQ title")
        cell.detailTextLabel?.text = NSLocalizedString("Get answers to questions you have", comment: "Subtitle for Browse our FAQ")
    }

    /// Contact Support cell.
    ///
    func configureContactSupport(cell: ValueOneTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Contact Support", comment: "Contact Support title")
        cell.detailTextLabel?.text = NSLocalizedString("Reach our happiness engineers who can help answer tough questions", comment: "Subtitle for Contact Support")
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
}


// MARK: - Convenience Methods
//
private extension HelpAndSupportViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}

// MARK: - Actions
//
private extension HelpAndSupportViewController {

    /// Browse our FAQ action
    ///
    func browseFaqWasPressed() {
        ZendeskManager.shared.showHelpCenterIfPossible(from: self)
    }

    /// Contact Support action
    ///
    func contactSupportWasPressed() {
        guard let navController = navigationController else {
            return
        }

        ZendeskManager.shared.showNewRequestIfPossible(from: navController)
    }

    /// My Tickets action
    ///
    func myTicketsWasPressed() {
        guard let navController = navigationController else {
            return
        }

        ZendeskManager.shared.showTicketListIfPossible(from: navController)
    }

    /// User's contact email action
    ///
    func contactEmailWasPressed() {
        guard let navController = navigationController else {
            return
        }

        ZendeskManager.shared.showSupportEmailPrompt(from: navController) { success in
            guard success else {
                return
            }
            // Tracking when the dialog's "OK" button is pressed, not necessarily if the value changed.
            WooAnalytics.shared.track(.supportIdentitySet)
            self.tableView.reloadData()
        }
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
        case .browseFaq:
            browseFaqWasPressed()
        case .contactSupport:
            contactSupportWasPressed()
        case .myTickets:
            myTicketsWasPressed()
        case .contactEmail:
            contactEmailWasPressed()
        }
    }
}


// MARK: - Private Types
//
private struct Constants {
    static let rowHeight = CGFloat(44)
    static let footerHeight = 44
    static let devEmail = "@automattic.com"
}

private struct Section {
    let title: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case browseFaq
    case contactSupport
    case myTickets
    case contactEmail

    var type: UITableViewCell.Type {
        switch self {
        case .browseFaq:
            return ValueOneTableViewCell.self
        case .contactSupport:
            return ValueOneTableViewCell.self
        case .myTickets:
            return ValueOneTableViewCell.self
        case .contactEmail:
            return ValueOneTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}
