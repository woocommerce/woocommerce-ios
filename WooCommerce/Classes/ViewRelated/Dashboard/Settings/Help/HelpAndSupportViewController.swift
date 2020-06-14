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
        // A stored Zendesk email address is preferred
        if let zendeskEmail = ZendeskManager.shared.userSupportEmail() {
            return zendeskEmail
        }

        // If no preferred ZD email exists, try the account email
        if let mainEmail = ServiceLocator.stores.sessionManager.defaultAccount?.email {
            return mainEmail
        }

        // If that doesn't exist, indicate we need them to set an email.
        return NSLocalizedString("Set email", comment: "Tells user to set an email that support can use for replies")
    }

    /// Indicates if the NavBar should display a dismiss button
    ///
    var displaysDismissAction = false


    // MARK: - Overridden Methods
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureSections()
        configureTableView()
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
        navigationItem.backBarButtonItem = UIBarButtonItem(title: String(), style: .plain, target: nil, action: nil)

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

    /// Disable Zendesk if configuration on ZD init fails.
    ///
    func configureSections() {
        let helpAndSupportTitle = NSLocalizedString("HOW CAN WE HELP?", comment: "My Store > Settings > Help & Support section title")

        guard ZendeskManager.shared.zendeskEnabled == true else {
            sections = [Section(title: helpAndSupportTitle, rows: [.helpCenter])]
            return
        }

        sections = [
            Section(title: helpAndSupportTitle, rows: [.helpCenter,
                                                       .contactSupport,
                                                       .myTickets,
                                                       .contactEmail,
                                                       .applicationLog])
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
        case let cell as ValueOneTableViewCell where row == .myTickets:
            configureMyTickets(cell: cell)
        case let cell as ValueOneTableViewCell where row == .contactEmail:
            configureMyContactEmail(cell: cell)
        case let cell as ValueOneTableViewCell where row == .applicationLog:
            configureApplicationLog(cell: cell)
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
        cell.textLabel?.isAccessibilityElement = true
        cell.textLabel?.accessibilityIdentifier = "contact-support-label"
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

    /// Help Center action
    ///
    func helpCenterWasPressed() {
        ZendeskManager.shared.showHelpCenter(from: self)
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

        ZendeskManager.shared.showSupportEmailPrompt(from: navController) { [weak self] (success, email) in
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
        performSegue(withIdentifier: Constants.appLogSegue, sender: nil)
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
        case .myTickets:
            myTicketsWasPressed()
        case .contactEmail:
            contactEmailWasPressed()
        case .applicationLog:
            applicationLogWasPressed()
        }
    }
}


// MARK: - Private Types
//
private struct Constants {
    static let rowHeight = CGFloat(44)
    static let footerHeight = 44
    static let appLogSegue = "ShowApplicationLogViewController"
}

private struct Section {
    let title: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case helpCenter
    case contactSupport
    case myTickets
    case contactEmail
    case applicationLog

    var type: UITableViewCell.Type {
        switch self {
        case .helpCenter:
            return ValueOneTableViewCell.self
        case .contactSupport:
            return ValueOneTableViewCell.self
        case .myTickets:
            return ValueOneTableViewCell.self
        case .contactEmail:
            return ValueOneTableViewCell.self
        case .applicationLog:
            return ValueOneTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}
