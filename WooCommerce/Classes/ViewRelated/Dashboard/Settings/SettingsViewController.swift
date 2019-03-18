import UIKit
import Yosemite
import MessageUI
import Gridicons
import SafariServices
import WordPressAuthenticator


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

    /// ResultsController: Loads Sites from the Storage Layer.
    ///
    private let resultsController: ResultsController<StorageSite> = {
        let storageManager = AppDelegate.shared.storageManager
        let predicate = NSPredicate(format: "isWooCommerceActive == YES")
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Sites pulled from the results controlelr
    ///
    private var sites = [Yosemite.Site]()

    /// Store Picker Coordinator
    ///
    private var storePickerCoordinator: StorePickerCoordinator?

    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        refreshResultsController()
        configureNavigation()
        configureMainView()
        configureSections()
        configureTableView()
        configureTableViewFooter()
        registerTableViewCells()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
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

    func refreshResultsController() {
        try? resultsController.performFetch()
        sites = resultsController.fetchedObjects
    }

    func configureTableViewFooter() {
        // `tableView.tableFooterView` can't handle a footerView that uses autolayout only.
        // Hence the container view with a defined frame.
        //
        let footerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: Constants.footerHeight))
        let footerView = TableFooterView.instantiateFromNib() as TableFooterView
        footerView.iconImage = Gridicon.iconOfType(.heartOutline)
        footerView.iconColor = StyleManager.wooGreyMid
        footerView.footnoteText = NSLocalizedString(
            "Made with love by Automattic",
            comment: "Tagline after the heart icon, displayed to the user"
        )
        footerView.footnoteColor = StyleManager.wooGreyMid
        tableView.tableFooterView = footerContainer
        footerContainer.addSubview(footerView)
    }

    func configureSections() {
        let selectedStoreTitle = NSLocalizedString(
            "Selected Store",
            comment: """
                My Store > Settings > Selected Store information section. This is the heading listed above the information row that \
                displays the store website and their username.
                """
            ).uppercased()
        let improveTheAppTitle = NSLocalizedString("Help Improve The App", comment: "My Store > Settings > Privacy settings section").uppercased()
        let aboutSettingsTitle = NSLocalizedString("About the app", comment: "My Store > Settings > About app section").uppercased()
        let otherTitle = NSLocalizedString("Other", comment: "My Store > Settings > Other app section").uppercased()

        let storeRows: [Row] = sites.count > 1 ?
            [.selectedStore, .switchStore] : [.selectedStore]

        sections = [
            Section(title: selectedStoreTitle, rows: storeRows, footerHeight: CGFloat.leastNonzeroMagnitude),
            Section(title: nil, rows: [.support], footerHeight: UITableView.automaticDimension),
            Section(title: improveTheAppTitle, rows: [.privacy, .featureRequest], footerHeight: UITableView.automaticDimension),
            Section(title: aboutSettingsTitle, rows: [.about, .licenses], footerHeight: UITableView.automaticDimension),
            Section(title: otherTitle, rows: [.appSettings], footerHeight: CGFloat.leastNonzeroMagnitude),
            Section(title: nil, rows: [.logout], footerHeight: CGFloat.leastNonzeroMagnitude)
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
        case let cell as HeadlineLabelTableViewCell where row == .selectedStore:
            configureSelectedStore(cell: cell)
        case let cell as BasicTableViewCell where row == .switchStore:
            configureSwitchStore(cell: cell)
        case let cell as BasicTableViewCell where row == .support:
            configureSupport(cell: cell)
        case let cell as BasicTableViewCell where row == .privacy:
            configurePrivacy(cell: cell)
        case let cell as BasicTableViewCell where row == .featureRequest:
            configureFeatureSuggestions(cell: cell)
        case let cell as BasicTableViewCell where row == .about:
            configureAbout(cell: cell)
        case let cell as BasicTableViewCell where row == .licenses:
            configureLicenses(cell: cell)
        case let cell as BasicTableViewCell where row == .appSettings:
            configureAppSettings(cell: cell)
        case let cell as BasicTableViewCell where row == .logout:
            configureLogout(cell: cell)
        default:
            fatalError()
        }
    }

    func configureSelectedStore(cell: HeadlineLabelTableViewCell) {
        cell.headline = siteUrl
        cell.body = accountName
        cell.selectionStyle = .none
    }

    func configureSwitchStore(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString(
            "Switch Store",
            comment: "This action allows the user to change stores without logging out and logging back in again."
        )
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

    func configureFeatureSuggestions(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Feature Request", comment: "Navigates to the feature request screen")
    }

    func configureAbout(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("WooCommerce", comment: "Navigates to about WooCommerce app screen")
    }

    func configureLicenses(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Open Source Licenses", comment: "Navigates to open source licenses screen")
    }

    func configureAppSettings(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Open Device Settings", comment: "Opens iOS's Device Settings for the app")
    }

    func configureLogout(cell: BasicTableViewCell) {
        cell.selectionStyle = .default
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = StyleManager.destructiveActionColor
        cell.textLabel?.text = NSLocalizedString("Log Out", comment: "Log out button title")
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
        let messageUnformatted = NSLocalizedString(
            "Are you sure you want to log out of the account %@?",
            comment: "Alert message to confirm a user meant to log out."
        )
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

    func switchStoreWasPressed() {
        WooAnalytics.shared.track(.settingsSelectedStoreTapped)
        if let navigationController = navigationController {
            storePickerCoordinator = StorePickerCoordinator(navigationController, config: .switchingStores)
            storePickerCoordinator?.start()
        }
    }

    func supportWasPressed() {
        WooAnalytics.shared.track(.settingsContactSupportTapped)
        performSegue(withIdentifier: Segues.helpSupportSegue, sender: nil)
    }

    func privacyWasPressed() {
        WooAnalytics.shared.track(.settingsPrivacySettingsTapped)
        performSegue(withIdentifier: Segues.privacySegue, sender: nil)
    }

    func aboutWasPressed() {
        WooAnalytics.shared.track(.settingsAboutLinkTapped)
        performSegue(withIdentifier: Segues.aboutSegue, sender: nil)
    }

    func licensesWasPressed() {
        WooAnalytics.shared.track(.settingsLicensesLinkTapped)
        performSegue(withIdentifier: Segues.licensesSegue, sender: nil)
    }

    func featureRequestWasPressed() {
        let safariViewController = SFSafariViewController(url: WooConstants.featureRequestURL)
        present(safariViewController, animated: true, completion: nil)
    }

    func appSettingsWasPressed() {
        guard let targetURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(targetURL)
    }

    func logOutUser() {
        StoresManager.shared.deauthenticate()
        navigationController?.popToRootViewController(animated: true)
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
        return sections[section].footerHeight
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

        // listed in the order they are displayed
        switch rowAtIndexPath(indexPath) {
        case .switchStore:
            switchStoreWasPressed()
        case .support:
            supportWasPressed()
        case .privacy:
            privacyWasPressed()
        case .featureRequest:
            featureRequestWasPressed()
        case .about:
            aboutWasPressed()
        case .licenses:
            licensesWasPressed()
        case .appSettings:
            appSettingsWasPressed()
        case .logout:
            logoutWasPressed()
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
    let footerHeight: CGFloat
}

private enum Row: CaseIterable {
    case selectedStore
    case switchStore
    case support
    case logout
    case privacy
    case featureRequest
    case about
    case licenses
    case appSettings

    var type: UITableViewCell.Type {
        switch self {
        case .selectedStore:
            return HeadlineLabelTableViewCell.self
        case .switchStore:
            return BasicTableViewCell.self
        case .support:
            return BasicTableViewCell.self
        case .logout:
            return BasicTableViewCell.self
        case .privacy:
            return BasicTableViewCell.self
        case .featureRequest:
            return BasicTableViewCell.self
        case .about:
            return BasicTableViewCell.self
        case .licenses:
            return BasicTableViewCell.self
        case .appSettings:
            return BasicTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

private struct Segues {
    static let privacySegue     = "ShowPrivacySettingsViewController"
    static let helpSupportSegue = "ShowHelpAndSupportViewController"
    static let aboutSegue       = "ShowAboutViewController"
    static let licensesSegue    = "ShowLicensesViewController"
}
