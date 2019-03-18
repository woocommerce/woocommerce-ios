import UIKit
import Gridicons
import SafariServices

class PrivacySettingsViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    /// Collect tracking info
    ///
    private var collectInfo = WooAnalytics.shared.userHasOptedIn {
        didSet {
            collectInfoWasUpdated(newValue: collectInfo)
        }
    }

    /// Send crash reports
    ///
    private var reportCrashes = AppDelegate.shared.fabricManager.userHasOptedIn {
        didSet {
            reportCrashesWasUpdated(newValue: reportCrashes)
        }
    }

    // MARK: - Overridden Methods
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureTableView()
        configureSections()

        registerTableViewCells()
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
        view.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = StyleManager.tableViewBackgroundColor
    }

    func configureSections() {
        sections = [
            Section(title: nil, rows: [.collectInfo, .shareInfo, .shareInfoPolicy, .privacyInfo, .privacyPolicy, .thirdPartyInfo, .thirdPartyPolicy]),
            Section(title: nil, rows: [.reportCrashes, .crashInfo])
        ]
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    /// Cells currently configured in the order they appear on screen.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as SwitchTableViewCell where row == .collectInfo:
            configureCollectInfo(cell: cell)
        case let cell as TopLeftImageTableViewCell where row == .shareInfo:
            configureShareInfo(cell: cell)
        case let cell as BasicTableViewCell where row == .shareInfoPolicy:
            configureCookiePolicy(cell: cell)
        case let cell as TopLeftImageTableViewCell where row == .privacyInfo:
            configurePrivacyInfo(cell: cell)
        case let cell as BasicTableViewCell where row == .privacyPolicy:
            configurePrivacyPolicy(cell: cell)
        case let cell as TopLeftImageTableViewCell where row == .thirdPartyInfo:
            configureCookieInfo(cell: cell)
        case let cell as BasicTableViewCell where row == .thirdPartyPolicy:
            configureCookiePolicy(cell: cell)
        case let cell as SwitchTableViewCell where row == .reportCrashes:
            configureReportCrashes(cell: cell)
        case let cell as TopLeftImageTableViewCell where row == .crashInfo:
            configureCrashInfo(cell: cell)
        default:
            fatalError()
        }
    }

    func configureCollectInfo(cell: SwitchTableViewCell) {
        // image
        cell.imageView?.image = Gridicon.iconOfType(.stats)
        cell.imageView?.tintColor = StyleManager.defaultTextColor

        // text
        cell.title = NSLocalizedString(
            "Collect Information",
            comment: "Settings > Privacy Settings > collect info section. Label for the `Collect Information` toggle."
        )

        // switch
        cell.isOn = collectInfo
        cell.onChange = { newValue in
            self.collectInfo = newValue
        }
    }

    func configureShareInfo(cell: TopLeftImageTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = Gridicon.iconOfType(.image)
        cell.imageView?.tintColor = .white
        cell.textLabel?.text = NSLocalizedString(
            "Share information with our analytics tool about your use of services while logged in to your WordPress.com account.",
            comment: "Settings > Privacy Settings > collect info section. Explains what the 'collect information' toggle is collecting"
        )
    }

    func configureCookiePolicy(cell: BasicTableViewCell) {
        // To align the 'Learn more' cell to the others, add an "invisible" image.
        cell.imageView?.image = Gridicon.iconOfType(.image)
        cell.imageView?.tintColor = .white
        cell.textLabel?.text = NSLocalizedString("Learn more", comment: "Settings > Privacy Settings. A text link to the cookie policy.")
        cell.textLabel?.textColor = StyleManager.wooCommerceBrandColor
    }

    func configurePrivacyInfo(cell: TopLeftImageTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = Gridicon.iconOfType(.image)
        cell.imageView?.tintColor = .white
        cell.textLabel?.text = NSLocalizedString("""
                                    This information helps us improve our products, make marketing to you more relevant, \
                                    personalize your WordPress.com experience, and more as detailed in our privacy policy.
                                    """,
            comment: "Settings > Privacy Settings > privacy info section. Explains what we do with the information we collect."
        )
    }

    func configurePrivacyPolicy(cell: BasicTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = Gridicon.iconOfType(.image)
        cell.imageView?.tintColor = .white
        cell.textLabel?.text = NSLocalizedString(
            "Read privacy policy",
            comment: "Settings > Privacy Settings > privacy policy info section. A text link to the privacy policy."
        )
        cell.textLabel?.textColor = StyleManager.wooCommerceBrandColor
    }

    func configureCookieInfo(cell: TopLeftImageTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = Gridicon.iconOfType(.image)
        cell.imageView?.tintColor = .white
        cell.textLabel?.text = NSLocalizedString(
            "We use other tracking tools, including some from third parties. Read about these and how to control them.",
            comment: "Settings > Privacy Settings > cookie info section. Explains what we do with the cookie information we collect."
        )
    }

    func configureReportCrashes(cell: SwitchTableViewCell) {
        // image
        cell.imageView?.image = Gridicon.iconOfType(.bug)
        cell.imageView?.tintColor = StyleManager.defaultTextColor

        // text
        cell.title = NSLocalizedString(
            "Report Crashes",
            comment: "Settings > Privacy Settings > report crashes section. Label for the `Report Crashes` toggle."
        )

        // switch
        cell.isOn = reportCrashes
        cell.onChange = { newValue in
            self.reportCrashes = newValue
        }
    }

    func configureCrashInfo(cell: TopLeftImageTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = Gridicon.iconOfType(.image)
        cell.imageView?.tintColor = .white
        cell.textLabel?.text = NSLocalizedString(
            "To help us improve the app’s performance and fix the occasional bug, enable automatic crash reports.",
            comment: "Settings > Privacy Settings > report crashes section. Explains what the 'report crashes' toggle does"
        )
    }


    // MARK: Actions
    //
    func collectInfoWasUpdated(newValue: Bool) {
        // Save the user's preference
        WooAnalytics.shared.setUserHasOptedIn(newValue)

        // This event will only report if the user has turned tracking back on
        WooAnalytics.shared.track(.settingsCollectInfoToggled)
    }

    func reportCrashesWasUpdated(newValue: Bool) {
        // Save user's preference
        AppDelegate.shared.fabricManager.setUserHasOptedIn(newValue)

        // This event will only report if the user has Analytics currently on
        WooAnalytics.shared.track(.settingsReportCrashesToggled)
    }


    /// Display Automattic's Cookie Policy web page
    ///
    func presentCookiePolicyWebView() {
        let safariViewController = SFSafariViewController(url: WooConstants.cookieURL)
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true, completion: nil)
    }

    /// Display Automattic's Privacy Policy web page
    ///
    func presentPrivacyPolicyWebView() {
        let safariViewController = SFSafariViewController(url: WooConstants.privacyURL)
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
            WooAnalytics.shared.track(.settingsShareInfoLearnMoreTapped)
            presentCookiePolicyWebView()
        case .thirdPartyPolicy:
            WooAnalytics.shared.track(.settingsThirdPartyLearnMoreTapped)
            presentCookiePolicyWebView()
        case .privacyPolicy:
            WooAnalytics.shared.track(.settingsPrivacyPolicyTapped)
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
            return TopLeftImageTableViewCell.self
        case .privacyPolicy:
            return BasicTableViewCell.self
        case .shareInfo:
            return TopLeftImageTableViewCell.self
        case .shareInfoPolicy:
            return BasicTableViewCell.self
        case .thirdPartyInfo:
            return TopLeftImageTableViewCell.self
        case .thirdPartyPolicy:
            return BasicTableViewCell.self
        case .reportCrashes:
            return SwitchTableViewCell.self
        case .crashInfo:
            return TopLeftImageTableViewCell.self
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}
