import UIKit
import MessageUI
import Gridicons
import SafariServices

protocol SettingsViewPresenter: AnyObject {
    func refreshViewContent()
}

// MARK: - SettingsViewController
//
final class SettingsViewController: UIViewController {
    typealias ViewModel = SettingsViewModelOutput & SettingsViewModelActionsHandler & SettingsViewModelInput

    private let viewModel: ViewModel

    /// Main TableView
    ///
    @IBOutlet private weak var tableView: UITableView!

    /// Store Picker Coordinator
    ///
    private var storePickerCoordinator: StorePickerCoordinator?

    init(viewModel: ViewModel = SettingsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.presenter = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        configureMainView()
        configureTableView()
        configureTableViewFooter()
        registerTableViewCells()
        viewModel.onViewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.updateFooterHeight()
    }
}

// MARK: - View Configuration
//
private extension SettingsViewController {

    func configureNavigation() {
        title = Localization.navigationTitle
    }

    func configureMainView() {
        view.backgroundColor = .listBackground
    }

    func configureTableView() {
        tableView.estimatedRowHeight = Constants.rowHeight
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = .listBackground

        tableView.dataSource = self
        tableView.delegate = self
    }

    func configureTableViewFooter() {
        // `tableView.tableFooterView` can't handle a footerView that uses autolayout only.
        // Hence the container view with a defined frame.
        //
        let footerContainer = UIView(frame: CGRect(x: 0, y: 0, width: Int(tableView.frame.width), height: Constants.footerHeight))
        let footerView = TableFooterView.instantiateFromNib() as TableFooterView
        footerView.iconImage = .heartOutlineImage
        footerView.footnote.attributedText = hiringAttributedText
        footerView.iconColor = .primary
        footerView.footnote.textAlignment = .center
        footerView.footnote.delegate = self

        tableView.tableFooterView = footerContainer
        footerContainer.addSubview(footerView)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        footerContainer.pinSubviewToAllEdges(footerView)
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
        }
    }

    /// Cells currently configured in the order they appear on screen
    ///
    func configure(_ cell: UITableViewCell, for row: Row) {
        switch cell {
        case let cell as HeadlineLabelTableViewCell where row == .selectedStore:
            configureSelectedStore(cell: cell)
        case let cell as BasicTableViewCell where row == .switchStore:
            configureSwitchStore(cell: cell)
        case let cell as BasicTableViewCell where row == .plugins:
            configurePlugins(cell: cell)
        case let cell as BasicTableViewCell where row == .support:
            configureSupport(cell: cell)
        case let cell as BasicTableViewCell where row == .inPersonPayments:
            configureInPersonPayments(cell: cell)
        case let cell as BasicTableViewCell where row == .installJetpack:
            configureInstallJetpack(cell: cell)
        case let cell as BasicTableViewCell where row == .privacy:
            configurePrivacy(cell: cell)
        case let cell as BasicTableViewCell where row == .betaFeatures:
            configureBetaFeatures(cell: cell)
        case let cell as BasicTableViewCell where row == .sendFeedback:
            configureSendFeedback(cell: cell)
        case let cell as BasicTableViewCell where row == .about:
            configureAbout(cell: cell)
        case let cell as BasicTableViewCell where row == .licenses:
            configureLicenses(cell: cell)
        case let cell as BasicTableViewCell where row == .deviceSettings:
            configureAppSettings(cell: cell)
        case let cell as BasicTableViewCell where row == .wormholy:
            configureWormholy(cell: cell)
        case let cell as BasicTableViewCell where row == .logout:
            configureLogout(cell: cell)
        case let cell as BasicTableViewCell where row == .whatsNew:
            configureWhatsNew(cell: cell)
        default:
            fatalError()
        }
    }

    func configureSelectedStore(cell: HeadlineLabelTableViewCell) {
        cell.update(headline: viewModel.siteName, body: viewModel.siteUrl)
        cell.selectionStyle = .none
    }

    func configureSwitchStore(cell: BasicTableViewCell) {
        cell.selectionStyle = .default
        cell.textLabel?.text = Localization.switchStore
    }

    func configurePlugins(cell: BasicTableViewCell) {
        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = Localization.plugins
    }

    func configureSupport(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = Localization.helpAndSupport
    }

    func configureInPersonPayments(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = Localization.inPersonPayments
    }

    func configureInstallJetpack(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = Localization.installJetpack
    }

    func configurePrivacy(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = Localization.privacySettings
    }

    func configureBetaFeatures(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = Localization.experimentalFeatures
        cell.accessibilityIdentifier = "settings-beta-features-button"
    }

    func configureSendFeedback(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = Localization.sendFeedback
    }

    func configureAbout(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = Localization.wooCommerce
    }

    func configureLicenses(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = Localization.openSourceLicenses
    }

    func configureAppSettings(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = Localization.openDeviceSettings
    }

    func configureWormholy(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = Localization.launchWormHolyDebug
    }

    func configureWhatsNew(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = Localization.whatsNew
    }

    func configureLogout(cell: BasicTableViewCell) {
        cell.selectionStyle = .default
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .error
        cell.textLabel?.text = Localization.logout
        cell.accessibilityIdentifier = "settings-log-out-button"
    }
}


// MARK: - Convenience Methods
//
private extension SettingsViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        viewModel.sections[indexPath.section].rows[indexPath.row]
    }
}


// MARK: - Actions
//
private extension SettingsViewController {

    func logoutWasPressed() {
        ServiceLocator.analytics.track(.settingsLogoutTapped)
        let messageFormatted = String(format: Localization.LogoutAlert.alertMessage, viewModel.accountName)
        let alertController = UIAlertController(title: "", message: messageFormatted, preferredStyle: .alert)

        alertController.addActionWithTitle(Localization.LogoutAlert.cancelButtonTitle, style: .cancel) { _ in
            ServiceLocator.analytics.track(.settingsLogoutConfirmation, withProperties: ["result": "negative"])
        }

        alertController.addDefaultActionWithTitle(Localization.LogoutAlert.logoutButtonTitle) { [weak self] _ in
            ServiceLocator.analytics.track(.settingsLogoutConfirmation, withProperties: ["result": "positive"])
            self?.logOutUser()
        }

        present(alertController, animated: true)
    }

    func switchStoreWasPressed() {
        ServiceLocator.analytics.track(.settingsSelectedStoreTapped)
        if let navigationController = navigationController {
            storePickerCoordinator = StorePickerCoordinator(navigationController, config: .switchingStores)
            storePickerCoordinator?.start()
            storePickerCoordinator?.onDismiss = { [weak self] in
                guard let self = self else {
                    return
                }
                self.viewModel.onStorePickerDismiss()
            }
        }
    }

    func sitePluginsWasPressed() {
        // TODO: do we need analytics to track tap here?
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return DDLogError("⛔️ Cannot find ID for current site to load plugins for!")
        }
        let viewModel = PluginListViewModel(siteID: siteID)
        let viewController = PluginListViewController(viewModel: viewModel)
        show(viewController, sender: self)
    }

    func supportWasPressed() {
        ServiceLocator.analytics.track(.settingsContactSupportTapped)
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: HelpAndSupportViewController.self) else {
            fatalError("Cannot instantiate `HelpAndSupportViewController` from Dashboard storyboard")
        }
        show(viewController, sender: self)
    }

    func inPersonPaymentsWasPressed() {
        let viewModel = InPersonPaymentsViewModel()
        let viewController = InPersonPaymentsViewController(viewModel: viewModel)
        show(viewController, sender: self)
    }

    func privacyWasPressed() {
        ServiceLocator.analytics.track(.settingsPrivacySettingsTapped)
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: PrivacySettingsViewController.self) else {
            fatalError("Cannot instantiate `PrivacySettingsViewController` from Dashboard storyboard")
        }
        show(viewController, sender: self)
    }

    func aboutWasPressed() {
        ServiceLocator.analytics.track(.settingsAboutLinkTapped)
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: AboutViewController.self) else {
            fatalError("Cannot instantiate `AboutViewController` from Dashboard storyboard")
        }
        show(viewController, sender: self)
    }

    func licensesWasPressed() {
        ServiceLocator.analytics.track(.settingsLicensesLinkTapped)
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: LicensesViewController.self) else {
            fatalError("Cannot instantiate `LicensesViewController` from Dashboard storyboard")
        }
        show(viewController, sender: self)
    }

    func betaFeaturesWasPressed() {
        ServiceLocator.analytics.track(.settingsBetaFeaturesButtonTapped)
        let betaFeaturesViewController = BetaFeaturesViewController()
        navigationController?.pushViewController(betaFeaturesViewController, animated: true)
    }

    func presentSurveyForFeedback() {
        let surveyNavigation = SurveyCoordinatingController(survey: .inAppFeedback)
        present(surveyNavigation, animated: true, completion: nil)
    }

    func deviceSettingsWasPressed() {
        guard let targetURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(targetURL)
    }

    func wormholyWasPressed() {
        // Fire a local notification, which fires Wormholy if enabled.
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "wormholy_fire"), object: nil)
    }

    func whatsNewWasPressed() {
        ServiceLocator.analytics.track(event: .featureAnnouncementShown(source: .appSettings))
        guard let announcement = viewModel.announcement else { return }
        let viewController = WhatsNewFactory.whatsNew(announcement) { [weak self] in
            self?.dismiss(animated: true)
        }
        present(viewController, animated: true, completion: nil)
    }

    func logOutUser() {
        ServiceLocator.stores.deauthenticate()
        navigationController?.popToRootViewController(animated: true)
    }

    func weAreHiringWasPressed(url: URL) {
        ServiceLocator.analytics.track(.settingsWereHiringTapped)

        WebviewHelper.launch(url, with: self)
    }
}


// MARK: - UITextViewDeletgate Conformance
//
extension SettingsViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL,
                  in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        weAreHiringWasPressed(url: URL)
        return false
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
        viewModel.sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        viewModel.sections[section].footerHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rowAtIndexPath(indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row)

        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        viewModel.sections[section].title
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
        case .plugins:
            sitePluginsWasPressed()
        case .support:
            supportWasPressed()
        case .inPersonPayments:
            inPersonPaymentsWasPressed()
        case .privacy:
            privacyWasPressed()
        case .betaFeatures:
            betaFeaturesWasPressed()
        case .sendFeedback:
            presentSurveyForFeedback()
        case .about:
            aboutWasPressed()
        case .licenses:
            licensesWasPressed()
        case .deviceSettings:
            deviceSettingsWasPressed()
        case .wormholy:
            wormholyWasPressed()
        case .whatsNew:
            whatsNewWasPressed()
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

// MARK: - Footer
//
private extension SettingsViewController {

    /// Returns the Settings Footer Attributed Text
    /// (which contains a link to the "Work with us" URL)
    ///
    var hiringAttributedText: NSAttributedString {
        let hiringText = Localization.hiring
        let hiringAttributes: [NSAttributedString.Key: Any] = [
            .font: StyleManager.footerLabelFont,
            .foregroundColor: UIColor.textSubtle
        ]

        let hiringAttrText = NSMutableAttributedString()
        hiringAttrText.append(hiringText.htmlToAttributedString)
        let range = NSRange(location: 0, length: hiringAttrText.length)
        hiringAttrText.addAttributes(hiringAttributes, range: range)

        return hiringAttrText
    }
}

extension SettingsViewController {

    struct Section {
        let title: String?
        let rows: [Row]
        let footerHeight: CGFloat
    }

    enum Row: CaseIterable {
        // Selected Store
        case selectedStore
        case switchStore

        // Plugins
        case plugins

        // Store settings
        case inPersonPayments
        case installJetpack

        // Help & Feedback
        case support
        case betaFeatures
        case sendFeedback

        // App Settings
        case privacy

        // About the App
        case about
        case whatsNew
        case licenses

        // Other
        case deviceSettings
        case wormholy

        // Logout
        case logout


        fileprivate var type: UITableViewCell.Type {
            switch self {
            case .selectedStore:
                return HeadlineLabelTableViewCell.self
            case .switchStore:
                return BasicTableViewCell.self
            case .plugins:
                return BasicTableViewCell.self
            case .support:
                return BasicTableViewCell.self
            case .inPersonPayments:
                return BasicTableViewCell.self
            case .installJetpack:
                return BasicTableViewCell.self
            case .logout:
                return BasicTableViewCell.self
            case .privacy:
                return BasicTableViewCell.self
            case .betaFeatures:
                return BasicTableViewCell.self
            case .sendFeedback:
                return BasicTableViewCell.self
            case .about:
                return BasicTableViewCell.self
            case .licenses:
                return BasicTableViewCell.self
            case .deviceSettings:
                return BasicTableViewCell.self
            case .wormholy:
                return BasicTableViewCell.self
            case .whatsNew:
                return BasicTableViewCell.self
            }
        }

        fileprivate var reuseIdentifier: String {
            return type.reuseIdentifier
        }
    }
}

// MARK: - SettingsViewPresenter Conformance
//
extension SettingsViewController: SettingsViewPresenter {

    func refreshViewContent() {
        tableView.reloadData()
    }
}

// MARK: - Localizations
//
private extension SettingsViewController {
    enum Localization {
        static let navigationTitle = NSLocalizedString(
            "Settings",
            comment: "Settings navigation title"
        )

        static let switchStore = NSLocalizedString(
            "Switch Store",
            comment: "This action allows the user to change stores without logging out and logging back in again."
        )

        static let plugins = NSLocalizedString(
            "Plugins",
            comment: "Navigates to Plugins screen."
        )

        static let helpAndSupport = NSLocalizedString(
            "Help & Support",
            comment: "Contact Support Action"
        )

        static let inPersonPayments = NSLocalizedString(
            "In-Person Payments",
            comment: "Navigates to In-Person Payments screen"
        )

        static let installJetpack = NSLocalizedString(
            "Install Jetpack",
            comment: "Navigates to Install Jetpack screen."
        )

        static let privacySettings = NSLocalizedString(
            "Privacy Settings",
            comment: "Navigates to Privacy Settings screen"
        )

        static let experimentalFeatures = NSLocalizedString(
            "Experimental Features",
            comment: "Navigates to experimental features screen"
        )

        static let sendFeedback = NSLocalizedString(
            "Send Feedback",
            comment: "Presents a survey to gather feedback from the user."
        )

        static let wooCommerce = NSLocalizedString(
            "WooCommerce",
            comment: "Navigates to about WooCommerce app screen"
        )

        static let openSourceLicenses = NSLocalizedString(
            "Open Source Licenses",
            comment: "Navigates to screen about open source licenses"
        )

        static let openDeviceSettings = NSLocalizedString(
            "Open Device Settings",
            comment: "Opens iOS's Device Settings for the app"
        )

        static let launchWormHolyDebug = NSLocalizedString(
            "Launch Wormholy Debug",
            comment: "Opens an internal library called Wormholy. Not visible to users."
        )

        static let whatsNew = NSLocalizedString(
            "What's New in WooCommerce",
            comment: "Navigates to screen containing the latest WooCommerce Features"
        )

        static let logout = NSLocalizedString(
            "Log Out",
            comment: "Log out button title"
        )

        static let hiring = NSLocalizedString(
            "Made with love by Automattic. <a href=\"https://automattic.com/work-with-us/\">We’re hiring!</a>",
            comment: "It reads 'Made with love by Automattic. We’re hiring!'. Place \'We’re hiring!' between `<a>` and `</a>`"
        )

        enum LogoutAlert {
            static let alertMessage = NSLocalizedString(
                "Are you sure you want to log out of the account %@?",
                comment: "Alert message to confirm a user meant to log out."
            )
            static let cancelButtonTitle = NSLocalizedString(
                "Back",
                comment: "Alert button title - dismisses alert, which cancels the log out attempt"
            )

            static let logoutButtonTitle = NSLocalizedString(
                "Log Out",
                comment: "Alert button title - confirms and logs out the user"
            )
        }
    }
}
