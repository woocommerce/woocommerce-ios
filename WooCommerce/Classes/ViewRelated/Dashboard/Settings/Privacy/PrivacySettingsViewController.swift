import UIKit
import Gridicons
import SafariServices
import Yosemite
import AutomatticTracks


class PrivacySettingsViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    /// Collect tracking info
    /// Mimic the behaviour of Calypso:
    /// the switch in https://wordpress.com/me/privacy
    /// is initalised as on, and visibly animated back to false after a reload
    private var collectInfo = true {
        didSet {
            configureSections()
            tableView.reloadData()
        }
    }

    /// Send crash reports
    ///
    private var reportCrashes = CrashLoggingSettings.didOptIn {
        didSet {
            CrashLoggingSettings.didOptIn = reportCrashes
        }
    }

    /// Pull To Refresh Support.
    ///
    private lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(pullToRefresh(sender:)), for: .valueChanged)
        return refreshControl
    }()

    // MARK: - Overridden Methods
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureTableView()
        configureSections()

        registerTableViewCells()

        loadAccountSettings()
    }

    @IBAction private func pullToRefresh(sender: UIRefreshControl) {
        loadAccountSettings {
            sender.endRefreshing()
        }
    }
}


// MARK: - Fetching Account & AccountSettings
private extension PrivacySettingsViewController {

    func loadAccountSettings(completion: (()-> Void)? = nil) {
        guard let defaultAccount = ServiceLocator.stores.sessionManager.defaultAccount else {
            return
        }

        let userID = defaultAccount.userID

        let action = AccountAction.synchronizeAccountSettings(userID: userID) { [weak self] (accountSettings, error) in
            guard let self = self,
                let accountSettings = accountSettings else {
                    return
            }

            // Switch is off when opting out of Tracks
            self.collectInfo = !accountSettings.tracksOptOut

            completion?()
        }

        ServiceLocator.stores.dispatch(action)
    }
}

// MARK: - View Configuration
//
private extension PrivacySettingsViewController {

    func configureNavigation() {
        title = NSLocalizedString("Privacy Settings", comment: "Privacy settings screen title")

        // Don't show the Settings title in the next-view's back button
        let backButton = UIBarButtonItem(title: String(),
                                         style: .plain,
                                         target: nil,
                                         action: nil)

        navigationItem.backBarButtonItem = backButton
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        tableView.refreshControl = refreshControl
    }

    func configureSections() {
        sections = [
            Section(title: nil, rows: [.collectInfo, .shareInfo, .shareInfoPolicy, .privacyInfo, .privacyPolicy, .thirdPartyInfo, .thirdPartyPolicy]),
            Section(title: nil, rows: [.reportCrashes, .crashInfo])
        ]
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    /// Cells currently configured in the order they appear on screen.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as SwitchTableViewCell where row == .collectInfo:
            configureCollectInfo(cell: cell)
        case let cell as BasicTableViewCell where row == .shareInfo:
            configureShareInfo(cell: cell)
        case let cell as BasicTableViewCell where row == .shareInfoPolicy:
            configureCookiePolicy(cell: cell)
        case let cell as BasicTableViewCell where row == .privacyInfo:
            configurePrivacyInfo(cell: cell)
        case let cell as BasicTableViewCell where row == .privacyPolicy:
            configurePrivacyPolicy(cell: cell)
        case let cell as BasicTableViewCell where row == .thirdPartyInfo:
            configureCookieInfo(cell: cell)
        case let cell as BasicTableViewCell where row == .thirdPartyPolicy:
            configureCookiePolicy(cell: cell)
        case let cell as SwitchTableViewCell where row == .reportCrashes:
            configureReportCrashes(cell: cell)
        case let cell as BasicTableViewCell where row == .crashInfo:
            configureCrashInfo(cell: cell)
        default:
            fatalError()
        }
    }

    func configureCollectInfo(cell: SwitchTableViewCell) {
        // image
        cell.imageView?.image = .statsImage
        cell.imageView?.tintColor = .text

        // text
        cell.title = NSLocalizedString(
            "Collect Information",
            comment: "Settings > Privacy Settings > collect info section. Label for the `Collect Information` toggle."
        )

        // switch
        cell.isOn = collectInfo
        cell.onChange = { [weak self] newValue in
            self?.collectInfoWasUpdated(newValue: newValue)
        }
    }

    func configureShareInfo(cell: BasicTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground
        cell.textLabel?.text = NSLocalizedString(
            "Share information with our analytics tool about your use of services while logged in to your WordPress.com account.",
            comment: "Settings > Privacy Settings > collect info section. Explains what the 'collect information' toggle is collecting"
        )
        configureInfo(cell: cell)
    }

    func configureCookiePolicy(cell: BasicTableViewCell) {
        // To align the 'Learn more' cell to the others, add an "invisible" image.
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground
        cell.textLabel?.text = NSLocalizedString("Learn more", comment: "Settings > Privacy Settings. A text link to the cookie policy.")
        cell.textLabel?.textColor = .accent
    }

    func configurePrivacyInfo(cell: BasicTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground
        cell.textLabel?.text = NSLocalizedString(
            "This information helps us improve our products, make marketing to you more relevant, personalize your WordPress.com experience, " +
            "and more as detailed in our privacy policy.",
            comment: "Settings > Privacy Settings > privacy info section. Explains what we do with the information we collect."
        )
        configureInfo(cell: cell)
    }

    func configurePrivacyPolicy(cell: BasicTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground
        cell.textLabel?.text = NSLocalizedString(
            "Read privacy policy",
            comment: "Settings > Privacy Settings > privacy policy info section. A text link to the privacy policy."
        )
        cell.textLabel?.textColor = .accent
    }

    func configureCookieInfo(cell: BasicTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground
        cell.textLabel?.text = NSLocalizedString(
            "We use other tracking tools, including some from third parties. Read about these and how to control them.",
            comment: "Settings > Privacy Settings > cookie info section. Explains what we do with the cookie information we collect."
        )
        configureInfo(cell: cell)
    }

    func configureReportCrashes(cell: SwitchTableViewCell) {
        // image
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .text

        // text
        cell.title = NSLocalizedString(
            "Report Crashes",
            comment: "Settings > Privacy Settings > report crashes section. Label for the `Report Crashes` toggle."
        )

        // switch
        cell.isOn = reportCrashes
        cell.onChange = { [weak self] newValue in
            self?.reportCrashes = newValue
        }
    }

    func configureCrashInfo(cell: BasicTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground
        cell.textLabel?.text = NSLocalizedString(
            "To help us improve the app’s performance and fix the occasional bug, enable automatic crash reports.",
            comment: "Settings > Privacy Settings > report crashes section. Explains what the 'report crashes' toggle does"
        )
        configureInfo(cell: cell)
    }

    func configureInfo(cell: BasicTableViewCell) {
        cell.textLabel?.numberOfLines = 0
    }

    // MARK: Actions
    //
    func collectInfoWasUpdated(newValue: Bool) {
        let userOptedOut = !newValue

        guard let defaultAccount = ServiceLocator.stores.sessionManager.defaultAccount else {
            return
        }

        let userID = defaultAccount.userID

        let action = AccountAction.updateAccountSettings(userID: userID, tracksOptOut: userOptedOut) { error in

            guard let _ = error else {
                ServiceLocator.analytics.setUserHasOptedOut(userOptedOut)

                return
            }
        }
        ServiceLocator.stores.dispatch(action)

        // This event will only report if the user has turned tracking back on
        ServiceLocator.analytics.track(.settingsCollectInfoToggled)
    }

    func reportCrashesWasUpdated(newValue: Bool) {
        // This event will only report if the user has Analytics currently on
        ServiceLocator.analytics.track(.settingsReportCrashesToggled)
    }

    /// Display Automattic's Cookie Policy web page
    ///
    func presentCookiePolicyWebView() {
        let safariViewController = SFSafariViewController(url: WooConstants.URLs.cookie.asURL())
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true, completion: nil)
    }

    /// Display Automattic's Privacy Policy web page
    ///
    func presentPrivacyPolicyWebView() {
        let safariViewController = SFSafariViewController(url: WooConstants.URLs.privacy.asURL())
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true, completion: nil)
    }
}

// MARK: - Convenience Methods
//
private extension PrivacySettingsViewController {
    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension PrivacySettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // The first section header always returns taller (32.0), but the design wants it the same height as the others.
        if section == 0 {
            return Constants.sectionHeight
        }

        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        // Give some breathing room to the table.
        let lastSection = sections.count - 1
        if section == lastSection {
            return UITableView.automaticDimension
        }

        // iOS 11 table bug. Must return a tiny value to collapse `nil` or `empty` section footers.
        return CGFloat.leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension PrivacySettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch sections[indexPath.section].rows[indexPath.row] {
        case .shareInfoPolicy:
            ServiceLocator.analytics.track(.settingsShareInfoLearnMoreTapped)
            presentCookiePolicyWebView()
        case .thirdPartyPolicy:
            ServiceLocator.analytics.track(.settingsThirdPartyLearnMoreTapped)
            presentCookiePolicyWebView()
        case .privacyPolicy:
            ServiceLocator.analytics.track(.settingsPrivacyPolicyTapped)
            presentPrivacyPolicyWebView()
        default:
            break
        }
    }
}


// MARK: - Private Types
//
private struct Constants {
    static let rowHeight = CGFloat(44)
    static let separatorInset = CGFloat(16)
    static let sectionHeight = CGFloat(18)
}

private struct Section {
    let title: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case collectInfo
    case privacyInfo
    case privacyPolicy
    case shareInfo
    case shareInfoPolicy
    case thirdPartyInfo
    case thirdPartyPolicy
    case reportCrashes
    case crashInfo

    var type: UITableViewCell.Type {
        switch self {
        case .collectInfo:
            return SwitchTableViewCell.self
        case .privacyInfo:
            return BasicTableViewCell.self
        case .privacyPolicy:
            return BasicTableViewCell.self
        case .shareInfo:
            return BasicTableViewCell.self
        case .shareInfoPolicy:
            return BasicTableViewCell.self
        case .thirdPartyInfo:
            return BasicTableViewCell.self
        case .thirdPartyPolicy:
            return BasicTableViewCell.self
        case .reportCrashes:
            return SwitchTableViewCell.self
        case .crashInfo:
            return BasicTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}
