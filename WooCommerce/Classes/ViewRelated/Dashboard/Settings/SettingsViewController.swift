import UIKit
import Yosemite
import MessageUI


// MARK: - SettingsViewController
//
class SettingsViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    /// Main Account's displayName
    ///
    private var accountName: String {
        return StoresManager.shared.sessionManager.defaultAccount?.displayName ?? String()
    }

    /// Main Site's URL
    ///
    private var siteUrl: String {
        let urlAsString = StoresManager.shared.sessionManager.defaultSite?.url as NSString?
        return urlAsString?.hostname() ?? String()
    }


    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureSections()
        configureTableView()
        configureTableViewFooter()
        registerTableViewCells()
    }
}


// MARK: - View Configuration
//
private extension SettingsViewController {

    func configureNavigation() {
        title = NSLocalizedString("Settings", comment: "Settings navigation title")
        // Don't show the Settings title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }

    func configureMainView() {
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func configureTableViewFooter() {
        // `tableView.tableFooterView` can't handle a footerView that uses autolayout only.
        // Hence the container view with a defined frame.
        //
        let footerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: Constants.footerHeight))
        let footerView = SettingsFooterView.makeFromNib()
        tableView.tableFooterView = footerContainer
        footerContainer.addSubview(footerView)
    }

    func configureSections() {
        let primaryStoreTitle = NSLocalizedString("PRIMARY STORE", comment: "My Store > Settings > Primary Store information section")
        let privacySettingsTitle = NSLocalizedString("HELP IMPROVE THE APP", comment: "My Store > Settings > Privacy settings section")

        sections = [
            Section(title: primaryStoreTitle, rows: [.primaryStore]),
            Section(title: nil, rows: [.support]),
            Section(title: privacySettingsTitle, rows: [.privacy]),
            Section(title: nil, rows: [.logout]),
        ]
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as HeadlineLabelTableViewCell where row == .primaryStore:
            configurePrimaryStore(cell: cell)
        case let cell as BasicTableViewCell where row == .support:
            configureSupport(cell: cell)
        case let cell as BasicTableViewCell where row == .privacy:
            configurePrivacy(cell: cell)
        case let cell as BasicTableViewCell where row == .logout:
            configureLogout(cell: cell)
        default:
            fatalError()
        }
    }

    func configurePrimaryStore(cell: HeadlineLabelTableViewCell) {
        cell.headline = siteUrl
        cell.body = accountName
    }

    func configureSupport(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Help & Support", comment: "Contact Support Action")
    }

    func configurePrivacy(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Privacy Settings", comment: "Navigates to Privacy Settings screen")
    }

    func configureLogout(cell: BasicTableViewCell) {
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = StyleManager.destructiveActionColor
        cell.textLabel?.text = NSLocalizedString("Logout account", comment: "Logout Action")
    }
}


// MARK: - Convenience Methods
//
private extension SettingsViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}


// MARK: - Actions
//
private extension SettingsViewController {

    func logoutWasPressed() {
        WooAnalytics.shared.track(.settingsLogoutTapped)
        let messageUnformatted = NSLocalizedString("Are you sure you want to log out of the account %@?", comment: "Alert message to confirm a user meant to log out.")
        let messageFormatted = String(format: messageUnformatted, accountName)
        let alertController = UIAlertController(title: "", message: messageFormatted, preferredStyle: .alert)

        let cancelText = NSLocalizedString("Back", comment: "Alert button title - dismisses alert, which cancels the log out attempt")
        alertController.addActionWithTitle(cancelText, style: .cancel) { _ in
            WooAnalytics.shared.track(.settingsLogoutConfirmation, withProperties: ["result": "negative"])
        }

        let logoutText = NSLocalizedString("Log Out", comment: "Alert button title - confirms and logs out the user")
        alertController.addDefaultActionWithTitle(logoutText) { _ in
            WooAnalytics.shared.track(.settingsLogoutConfirmation, withProperties: ["result": "positive"])
            self.logOutUser()
        }

        present(alertController, animated: true)
    }

    func supportWasPressed() {
        WooAnalytics.shared.track(.settingsContactSupportTapped)
        guard shouldDisplayEmailComposer() else {
            displayContactUsAlert()
            return
        }

        displaySupportEmailComposer()
    }

    func privacyWasPressed() {
        WooAnalytics.shared.track(.settingsPrivacySettingsTapped)
        performSegue(withIdentifier: Segues.privacySegue, sender: nil)
    }

    func logOutUser() {
        StoresManager.shared.deauthenticate()
        navigationController?.popToRootViewController(animated: true)
    }

    func shouldDisplayEmailComposer() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }

    func displayContactUsAlert() {
        let messageUnformatted = NSLocalizedString("Please contact us via email:\n %@", comment: "Alert message to confirm a user meant to log out.")
        let messageFormatted = String(format: messageUnformatted, WooConstants.supportMail)
        let alertController = UIAlertController(title: "", message: messageFormatted, preferredStyle: .alert)

        let cancelText = NSLocalizedString("Dismiss", comment: "Dismiss Alert Action")
        alertController.addActionWithTitle(cancelText, style: .cancel)

        present(alertController, animated: true)
    }

    func displaySupportEmailComposer() {
        // Workaround: MFMailCompose isn't *FULLY* picking up UINavigationBar's WC's appearance. Title / Buttons look awful.
        // We're falling back to iOS's default appearance
        UINavigationBar.applyDefaultAppearance()

        // Subject + Composer
        let subjectUnformatted = NSLocalizedString("WooCommerce iOS %@ support", comment: "Support Email's Title")
        let subjectFormatted = String(format: subjectUnformatted, Bundle.main.detailedVersionNumber())

        let controller = MFMailComposeViewController()
        controller.setSubject(subjectFormatted)
        controller.setToRecipients([WooConstants.supportMail])
        controller.mailComposeDelegate = self

        // Display the Mail Composer
        present(controller, animated: true, completion: nil)
    }
}


// MARK: - MFMailComposeViewControllerDelegate Conformance
//
extension SettingsViewController: MFMailComposeViewControllerDelegate {

    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)

        // Workaround: Restore WC's navBar appearance
        UINavigationBar.applyWooAppearance()
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension SettingsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section headers.
        return CGFloat.leastNonzeroMagnitude
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
extension SettingsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch rowAtIndexPath(indexPath) {
        case .logout:
            logoutWasPressed()
        case .support:
            supportWasPressed()
        case .privacy:
            privacyWasPressed()
        default:
            break
        }
    }
}


// MARK: - Private Types
//

private struct Constants {
    static let rowHeight = CGFloat(44)
    static let footerHeight = 90
}

private struct Section {
    let title: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case primaryStore
    case support
    case logout
    case privacy

    var type: UITableViewCell.Type {
        switch self {
        case .primaryStore:
            return HeadlineLabelTableViewCell.self
        case .support:
            return BasicTableViewCell.self
        case .logout:
            return BasicTableViewCell.self
        case .privacy:
            return BasicTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

private struct Segues {
    static let privacySegue = "ShowPrivacySettingsViewController"
}
