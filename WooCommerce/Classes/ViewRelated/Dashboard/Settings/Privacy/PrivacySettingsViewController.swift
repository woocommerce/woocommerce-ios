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
    private var collectInfo: Bool = true

    // MARK: - Overridden Methods
    //
    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureTableView()
        configureSections()

        registerTableViewCells()
        getUserPreferences()
    }
}


// MARK: - View Configuration
//
private extension PrivacySettingsViewController {

    func configureNavigation() {
        title = NSLocalizedString("Privacy settings", comment: "Privacy settings screen title")

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
            Section(title: nil, rows: [.collectInfo, .shareInfo, .shareInfoPolicy]),
            Section(title: nil, rows: [.privacyInfo, .privacyPolicy]),
            Section(title: nil, rows: [.thirdPartyInfo, .thirdPartyPolicy]),
        ]
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.register(row.type.loadNib(), forCellReuseIdentifier: row.reuseIdentifier)
        }
    }

    func getUserPreferences() {
        collectInfo = !WooAnalytics.shared.userHasOptedOut()
    }

    /// Cells currently configured in the order they appear on screen.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as BasicTableViewCell where row == .collectInfo:
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
        default:
            fatalError()
        }
    }

    func configureCollectInfo(cell: BasicTableViewCell) {
        // image
        cell.imageView?.image = Gridicon.iconOfType(.stats)
        cell.imageView?.tintColor = StyleManager.defaultTextColor

        // text
        cell.textLabel?.text = NSLocalizedString("Collect information", comment: "Settings > Privacy Settings > collect info section. Label the `Collect information` toggle.")

        // switch
        let toggleSwitch = UISwitch()
        toggleSwitch.setOn(collectInfo, animated: true)
        toggleSwitch.onTintColor = StyleManager.wooCommerceBrandColor
        toggleSwitch.on(.touchUpInside) { (toggleSwitch) in
            self.toggleCollectInfo()
        }
        cell.accessoryView = toggleSwitch

        // action
        let gestureRecognizer = UITapGestureRecognizer()
        gestureRecognizer.on { [weak self] gesture in
            guard let self = self else {
                return
            }

            self.toggleCollectInfo()
            toggleSwitch.setOn(self.collectInfo, animated: true)
        }

        cell.addGestureRecognizer(gestureRecognizer)
    }

    func configureShareInfo(cell: TopLeftImageTableViewCell) {
        cell.imageView?.image = Gridicon.iconOfType(.infoOutline)
        cell.imageView?.tintColor = StyleManager.defaultTextColor
        cell.textLabel?.text = NSLocalizedString("Share information with our analytics tool about your use of services while logged in to your WordPress.com account.", comment: "Settings > Privacy Settings > collect info section. Explains what the 'collect information' toggle is collecting")
    }

    func configureCookiePolicy(cell: BasicTableViewCell) {
        // To align the 'Learn more' cell to the others, add an "invisible" image.
        cell.imageView?.image = Gridicon.iconOfType(.image)
        cell.imageView?.tintColor = .white
        cell.textLabel?.text = NSLocalizedString("Learn more", comment: "Settings > Privacy Settings. A text link to the cookie policy.")
        cell.textLabel?.textColor = StyleManager.wooCommerceBrandColor
    }

    func configurePrivacyInfo(cell: TopLeftImageTableViewCell) {
        cell.imageView?.image = Gridicon.iconOfType(.userCircle)
        cell.imageView?.tintColor = StyleManager.defaultTextColor
        cell.textLabel?.text = NSLocalizedString("This information helps us improve our products, make marketing to you more relevant, personalize your WordPress.com experience, and more as detailed in our privacy policy.", comment: "Settings > Privacy Settings > privacy info section. Explains what we do with the information we collect.")
    }

    func configurePrivacyPolicy(cell: BasicTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = Gridicon.iconOfType(.image)
        cell.imageView?.tintColor = .white
        cell.textLabel?.text = NSLocalizedString("Read privacy policy", comment: "Settings > Privacy Settings > privacy policy info section. A text link to the privacy policy.")
        cell.textLabel?.textColor = StyleManager.wooCommerceBrandColor
    }

    func configureCookieInfo(cell: TopLeftImageTableViewCell) {
        cell.imageView?.image = Gridicon.iconOfType(.briefcase)
        cell.imageView?.tintColor = StyleManager.defaultTextColor
        cell.textLabel?.text = NSLocalizedString("We use other tracking tools, including some from third parties. Read about these and how to control them.", comment: "Settings > Privacy Settings > cookie info section. Explains what we do with the cookie information we collect.")
    }


    // MARK: Actions
    //
    func toggleCollectInfo() {
        // set the user's new preference
        collectInfo = !collectInfo

        // create the opt out bool
        let optOut = !collectInfo

        // save the user's preference
        WooAnalytics.shared.setUserHasOptedOut(optOut)
        AppDelegate.shared.fabricManager.setUserHasOptedOutValue(optOut)

        // this event will only report if the user has turned tracking back on
        WooAnalytics.shared.track(.settingsCollectInfoToggled)
    }


    /// Display Automattic's Cookie Policy web page
    ///
    func presentCookiePolicyWebView() {
        guard let cookieURL = Constants.cookieURL else {
            return
        }

        let safariViewController = SFSafariViewController(url: cookieURL)
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true, completion: nil)
    }

    /// Display Automattic's Privacy Policy web page
    ///
    func presentPrivacyPolicyWebView() {
        guard let privacyURL = Constants.privacyURL else {
            return
        }

        let safariViewController = SFSafariViewController(url: privacyURL)
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
    static let cookieURL = URL(string:"https://automattic.com/cookies/")
    static let privacyURL = URL(string: "https://automattic.com/privacy/")
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

    var type: UITableViewCell.Type {
        switch self {
        case .collectInfo:
            return BasicTableViewCell.self
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
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}
