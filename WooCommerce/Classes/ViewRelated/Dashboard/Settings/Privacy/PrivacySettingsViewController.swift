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

    /// Defines if the `privacyChoices` feature is enabled.
    ///
    private var isPrivacyChoicesEnabled: Bool {
        ServiceLocator.featureFlagService.isFeatureFlagEnabled(.privacyChoices)
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

        loadAccountSettings()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.updateHeaderHeight()
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
            completion?()
            return
        }

        let userID = defaultAccount.userID

        let action = AccountAction.synchronizeAccountSettings(userID: userID) { [weak self] result in
            if case let .success(accountSettings) = result {
                // Switch is off when opting out of Tracks
                self?.collectInfo = !accountSettings.tracksOptOut
            }

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
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground
        tableView.refreshControl = refreshControl

        if isPrivacyChoicesEnabled {
            tableView.tableHeaderView = createTableHeaderView()
            tableView.updateHeaderHeight()
            tableView.sectionFooterHeight = UITableView.automaticDimension
            tableView.estimatedSectionFooterHeight = 100
        }
    }

    func configureSections() {
        if isPrivacyChoicesEnabled {
            return sections = [
                Section(title: Localization.tracking, footer: nil, rows: [.analytics, .analyticsInfo]),
                Section(title: Localization.morePrivacyOptions, footer: Localization.morePrivacyOptionsFooter, rows: [.morePrivacy]),
                Section(title: Localization.reports, footer: nil, rows: [.reportCrashes, .crashInfo])
            ]
        } else {
            return sections = [
                Section(title: nil,
                        footer: nil,
                        rows: [.collectInfo, .shareInfo, .shareInfoPolicy, .privacyInfo, .privacyPolicy, .thirdPartyInfo, .thirdPartyPolicy]),
                Section(title: nil, footer: nil, rows: [.reportCrashes, .crashInfo])
            ]
        }
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
        case let cell as SwitchTableViewCell where row == .analytics:
            configureAnalytics(cell: cell)
        case let cell as BasicTableViewCell where row == .analyticsInfo:
            configureAnalyticsInfo(cell: cell)
        case let cell as HeadlineLabelTableViewCell where row == .morePrivacy:
            configureMorePrivacy(cell: cell)
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

    func configureAnalytics(cell: SwitchTableViewCell) {
        // image
        cell.imageView?.image = nil

        // text
        cell.title = NSLocalizedString(
            "Analytics",
            comment: "Analytics toggle title in the privacy screen."
        )

        // switch
        cell.isOn = collectInfo
        cell.onChange = { [weak self] newValue in
            self?.collectInfoWasUpdated(newValue: newValue)
        }
    }

    func configureAnalyticsInfo(cell: BasicTableViewCell) {
        cell.imageView?.image = nil
        cell.textLabel?.text = NSLocalizedString(
            "These cookies allow us to optimize performance by collecting information on how users interact with our mobile apps.",
            comment: "Analytics toggle description in the privacy screen."
        )
        configureInfo(cell: cell)
    }

    func configureMorePrivacy(cell: HeadlineLabelTableViewCell) {
        cell.imageView?.image = nil
        cell.update(style: .subheadline,
                    headline: NSLocalizedString("Advertising Option", comment: "More Privacy Options section title in the privacy screen."),
                    body: NSLocalizedString("More Privacy Options Available. Check here to learn more.",
                                            comment: "More Privacy toggle section in the privacy screen."))
        cell.accessoryType = .disclosureIndicator
    }

    func configureMorePrivacyInfo(cell: BasicTableViewCell) {
        cell.imageView?.image = nil
        cell.textLabel?.text = NSLocalizedString("More Privacy Options Available. Check here to learn more.",
                                                 comment: "More Privacy toggle section in the privacy screen.")
        cell.accessoryType = .disclosureIndicator
        configureInfo(cell: cell)
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
        cell.imageView?.tintColor = .listForeground(modal: false)
        cell.textLabel?.text = NSLocalizedString(
            "Share information with our analytics tool about your use of services while logged in to your WordPress.com account.",
            comment: "Settings > Privacy Settings > collect info section. Explains what the 'collect information' toggle is collecting"
        )
        configureInfo(cell: cell)
    }

    func configureCookiePolicy(cell: BasicTableViewCell) {
        // To align the 'Learn more' cell to the others, add an "invisible" image.
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground(modal: false)
        cell.textLabel?.text = NSLocalizedString("Learn more", comment: "Settings > Privacy Settings. A text link to the cookie policy.")
        cell.textLabel?.textColor = .accent
    }

    func configurePrivacyInfo(cell: BasicTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground(modal: false)
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
        cell.imageView?.tintColor = .listForeground(modal: false)
        cell.textLabel?.text = NSLocalizedString(
            "Read privacy policy",
            comment: "Settings > Privacy Settings > privacy policy info section. A text link to the privacy policy."
        )
        cell.textLabel?.textColor = .accent
    }

    func configureCookieInfo(cell: BasicTableViewCell) {
        // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
        cell.imageView?.image = .invisibleImage
        cell.imageView?.tintColor = .listForeground(modal: false)
        cell.textLabel?.text = NSLocalizedString(
            "We use other tracking tools, including some from third parties. Read about these and how to control them.",
            comment: "Settings > Privacy Settings > cookie info section. Explains what we do with the cookie information we collect."
        )
        configureInfo(cell: cell)
    }

    func configureReportCrashes(cell: SwitchTableViewCell) {
        // image
        if isPrivacyChoicesEnabled {
            cell.imageView?.image = nil
        } else {
            cell.imageView?.image = .invisibleImage
            cell.imageView?.tintColor = .text
        }

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
        if isPrivacyChoicesEnabled {
            cell.imageView?.image = nil
        } else {
            // To align the 'Read privacy policy' cell to the others, add an "invisible" image.
            cell.imageView?.image = .invisibleImage
            cell.imageView?.tintColor = .listForeground(modal: false)
        }
        cell.textLabel?.text = NSLocalizedString(
            "To help us improve the app’s performance and fix the occasional bug, enable automatic crash reports.",
            comment: "Settings > Privacy Settings > report crashes section. Explains what the 'report crashes' toggle does"
        )
        configureInfo(cell: cell)
    }

    func configureInfo(cell: BasicTableViewCell) {
        cell.textLabel?.numberOfLines = 0
        if isPrivacyChoicesEnabled {
            cell.textLabel?.applySubheadlineStyle()
            cell.textLabel?.textColor = .textSubtle
        }
    }

    /// Creates the table header view.
    ///
    func createTableHeaderView() -> UIView {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = Localization.tableTitle
        label.applyFootnoteStyle()
        label.numberOfLines = 0

        let container = UIView(frame: .init(x: 0, y: 0, width: Int(self.tableView.frame.width), height: 0))
        container.addSubview(label)
        NSLayoutConstraint.activate([
            container.readableContentGuide.leadingAnchor.constraint(equalTo: label.leadingAnchor, constant: -Constants.headerTitleInsets.left),
            container.readableContentGuide.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: Constants.headerTitleInsets.right),
            container.readableContentGuide.topAnchor.constraint(equalTo: label.topAnchor, constant: -Constants.headerTitleInsets.top),
            container.readableContentGuide.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: Constants.headerTitleInsets.bottom),
        ])
        return container
    }

    // MARK: Actions
    //
    func collectInfoWasUpdated(newValue: Bool) {
        let userOptedOut = !newValue

        guard let defaultAccount = ServiceLocator.stores.sessionManager.defaultAccount else {
            return
        }

        let userID = defaultAccount.userID

        let action = AccountAction.updateAccountSettings(userID: userID, tracksOptOut: userOptedOut) { result in
            if case .success = result {
                ServiceLocator.analytics.setUserHasOptedOut(userOptedOut)
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
        WebviewHelper.launch(WooConstants.URLs.cookie.asURL(), with: self)
    }

    /// Display Automattic's Privacy Policy web page
    ///
    func presentPrivacyPolicyWebView() {
        WebviewHelper.launch(WooConstants.URLs.privacy.asURL(), with: self)
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

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let footer = sections[section].footer else {
            return nil
        }

        var attr = NSMutableAttributedString(string: footer, attributes: [.foregroundColor: UIColor.textSubtle, .font: UIFont.caption1])
        attr.setAsLink(textToFind: "Cookie Policy", linkURL: "https://automattic.com/cookies/")
        attr.setAsLink(textToFind: "Privacy Policy", linkURL: "https://automattic.com/privacy/")

        let textView = UITextView(frame: .zero)
        textView.font = .caption1
        textView.textColor = .textSubtle
        textView.attributedText = attr
        textView.textContainer.maximumNumberOfLines = 0
        textView.backgroundColor = .clear
        textView.textContainerInset = Constants.footerInsets
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.delegate = self

        var linkTextAttributes = textView.linkTextAttributes ?? [:]
        linkTextAttributes[.underlineColor] = UIColor.clear
        linkTextAttributes[.foregroundColor] = UIColor.primary
        textView.linkTextAttributes = linkTextAttributes

        return textView
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

extension PrivacySettingsViewController {
    enum Localization {
        static let tableTitle = NSLocalizedString("We value your privacy. " +
                                                  "Your personal data is used to optimize our mobile apps, improve security, " +
                                                  "conduct analytics and marketing activities, and enhance your user experience.",
                                                  comment: "Main description on the privacy screen.")
        static let tracking = NSLocalizedString("Tracking", comment: "Title of the tracking section on the privacy screen")
        static let reports = NSLocalizedString("Reports", comment: "Title of the report section on the privacy screen")
        static let morePrivacyOptions = NSLocalizedString("More Privacy Options", comment: "Title of the more privacy options section on the privacy screen")
        static let morePrivacyOptionsFooter = NSLocalizedString("To learn more about how we use your data to optimize our mobile apps, " +
                                                                "enhance your experience, and deliver relevant marketing, " +
                                                                "learn more in our Privacy Policy and Cookie Policy." + "\n",
                                                                comment: "Footer of the more privacy options section on the privacy screen")
    }
}

private struct Constants {
    static let rowHeight = CGFloat(44)
    static let separatorInset = CGFloat(16)
    static let sectionHeight = CGFloat(18)
    static let headerTitleInsets = UIEdgeInsets(top: 16, left: 14, bottom: 32, right: 14)
    static let footerInsets = UIEdgeInsets(top: 8, left: 16, bottom: 16, right: 16)
    static let footerPadding = CGFloat(44)
}

private struct Section {
    let title: String?
    let footer: String?
    let rows: [Row]
}

private enum Row: CaseIterable {
    case analytics
    case analyticsInfo
    case morePrivacy
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
        case .analytics:
            return SwitchTableViewCell.self
        case .analyticsInfo:
            return BasicTableViewCell.self
        case .morePrivacy:
            return HeadlineLabelTableViewCell.self
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

extension PrivacySettingsViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print("Link tapped")
        return false
    }
}
