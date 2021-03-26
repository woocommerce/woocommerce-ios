import UIKit
import Yosemite
import MessageUI
import Gridicons
import SafariServices
import WordPressAuthenticator


// MARK: - SettingsViewController
//
final class SettingsViewController: UIViewController {

    /// Main TableView
    ///
    @IBOutlet private weak var tableView: UITableView!

    /// Table Sections to be rendered
    ///
    private var sections = [Section]()

    /// Main Account's displayName
    ///
    private var accountName: String {
        return ServiceLocator.stores.sessionManager.defaultAccount?.displayName ?? String()
    }

    /// Main Site's Name
    ///
    private var siteName: String {
        let nameAsString = ServiceLocator.stores.sessionManager.defaultSite?.name as String?
        return nameAsString ?? String()
    }

    /// Main Site's URL
    ///
    private var siteUrl: String {
        let urlAsString = ServiceLocator.stores.sessionManager.defaultSite?.url as NSString?
        return urlAsString?.hostname() ?? String()
    }

    /// ResultsController: Loads Sites from the Storage Layer.
    ///
    private let resultsController: ResultsController<StorageSite> = {
        let storageManager = ServiceLocator.storageManager
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
        configureTableView()
        configureTableViewFooter()
        registerTableViewCells()
        refreshViewContent()
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
        title = NSLocalizedString("Settings", comment: "Settings navigation title")
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

    func refreshViewContent() {
        configureSections()
        tableView.reloadData()
    }

    func configureSections() {
        let selectedStoreTitle = NSLocalizedString(
            "Selected Store",
            comment: "My Store > Settings > Selected Store information section. " +
            "This is the heading listed above the information row that displays the store website and their username."
        ).uppercased()
        let storeSettingsTitle = NSLocalizedString(
            "Store Settings",
            comment: "My Store > Settings > Store Settings section title"
        ).uppercased()
        let helpAndFeedbackTitle = NSLocalizedString(
            "Help & Feedback",
            comment: "My Store > Settings > Help and Feedback settings section title"
        ).uppercased()
        let appSettingsTitle = NSLocalizedString(
            "App Settings",
            comment: "My Store > Settings > App (Application) settings section title"
        ).uppercased()
        let aboutTheAppTitle = NSLocalizedString(
            "About the App",
            comment: "My Store > Settings > About the App (Application) section title"
        ).uppercased()
        let otherTitle = NSLocalizedString(
            "Other",
            comment: "My Store > Settings > Other app section"
        ).uppercased()

        let storeRows: [Row] = sites.count > 1 ?
            [.selectedStore, .switchStore] : [.selectedStore]

        // Selected Store
        sections = [
            Section(title: selectedStoreTitle, rows: storeRows, footerHeight: UITableView.automaticDimension),
        ]

        // Store Settings
        if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.cardPresentPayments) {
            sections.append(Section(title: storeSettingsTitle, rows: [.cardReaders], footerHeight: UITableView.automaticDimension))
        }

        // Help & Feedback
        if couldShowBetaFeaturesRow() {
            sections.append(Section(title: helpAndFeedbackTitle, rows: [.support, .betaFeatures, .sendFeedback], footerHeight: UITableView.automaticDimension))
        } else {
            sections.append(Section(title: helpAndFeedbackTitle, rows: [.support, .sendFeedback], footerHeight: UITableView.automaticDimension))
        }

        // App Settings
        sections.append(Section(title: appSettingsTitle, rows: [.privacy], footerHeight: UITableView.automaticDimension))

        // About the App
        sections.append(Section(title: aboutTheAppTitle, rows: [.about, .licenses], footerHeight: UITableView.automaticDimension))

        // Other
        #if DEBUG
        sections.append(Section(title: otherTitle, rows: [.deviceSettings, .wormholy], footerHeight: CGFloat.leastNonzeroMagnitude))
        #else
        sections.append(Section(title: otherTitle, rows: [.deviceSettings], footerHeight: CGFloat.leastNonzeroMagnitude))
        #endif

        sections.append(Section(title: nil, rows: [.logout], footerHeight: CGFloat.leastNonzeroMagnitude))
    }

    func registerTableViewCells() {
        for row in Row.allCases {
            tableView.registerNib(for: row.type)
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
        case let cell as BasicTableViewCell where row == .cardReaders:
            configureCardReaders(cell: cell)
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
        default:
            fatalError()
        }
    }

    func configureSelectedStore(cell: HeadlineLabelTableViewCell) {
        cell.update(headline: siteName, body: siteUrl)
        cell.selectionStyle = .none
    }

    func configureSwitchStore(cell: BasicTableViewCell) {
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

    func configureCardReaders(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Manage Card Reader", comment: "Navigates to Card Reader management screen")
    }

    func configurePrivacy(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Privacy Settings", comment: "Navigates to Privacy Settings screen")
    }

    func configureBetaFeatures(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Experimental Features", comment: "Navigates to experimental features screen")
        cell.accessibilityIdentifier = "settings-beta-features-button"
    }

    func configureSendFeedback(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Send Feedback", comment: "Presents a survey to gather feedback from the user.")
    }

    func configureAbout(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("WooCommerce", comment: "Navigates to about WooCommerce app screen")
    }

    func configureLicenses(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Open Source Licenses", comment: "Navigates to screen about open source licenses")
    }

    func configureAppSettings(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Open Device Settings", comment: "Opens iOS's Device Settings for the app")
    }

    func configureWormholy(cell: BasicTableViewCell) {
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        cell.textLabel?.text = NSLocalizedString("Launch Wormholy Debug",
                                                 comment: "Opens an internal library called Wormholy. Not visible to users.")
    }

    func configureLogout(cell: BasicTableViewCell) {
        cell.selectionStyle = .default
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .error
        cell.textLabel?.text = NSLocalizedString("Log Out", comment: "Log out button title")
        cell.accessibilityIdentifier = "settings-log-out-button"
    }
}


// MARK: - Convenience Methods
//
private extension SettingsViewController {

    func rowAtIndexPath(_ indexPath: IndexPath) -> Row {
        return sections[indexPath.section].rows[indexPath.row]
    }

    /// This is false because there are no ongoing experiments
    func couldShowBetaFeaturesRow() -> Bool {
        false
    }
}


// MARK: - Actions
//
private extension SettingsViewController {

    func logoutWasPressed() {
        ServiceLocator.analytics.track(.settingsLogoutTapped)
        let messageUnformatted = NSLocalizedString(
            "Are you sure you want to log out of the account %@?",
            comment: "Alert message to confirm a user meant to log out."
        )
        let messageFormatted = String(format: messageUnformatted, accountName)
        let alertController = UIAlertController(title: "", message: messageFormatted, preferredStyle: .alert)

        let cancelText = NSLocalizedString("Back", comment: "Alert button title - dismisses alert, which cancels the log out attempt")
        alertController.addActionWithTitle(cancelText, style: .cancel) { _ in
            ServiceLocator.analytics.track(.settingsLogoutConfirmation, withProperties: ["result": "negative"])
        }

        let logoutText = NSLocalizedString("Log Out", comment: "Alert button title - confirms and logs out the user")
        alertController.addDefaultActionWithTitle(logoutText) { _ in
            ServiceLocator.analytics.track(.settingsLogoutConfirmation, withProperties: ["result": "positive"])
            self.logOutUser()
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
                self.refreshViewContent()
            }
        }
    }

    func supportWasPressed() {
        ServiceLocator.analytics.track(.settingsContactSupportTapped)
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: HelpAndSupportViewController.self) else {
            fatalError("Cannot instantiate `HelpAndSupportViewController` from Dashboard storyboard")
        }
        show(viewController, sender: self)
    }

    func cardReadersWasPressed() {
        ServiceLocator.analytics.track(.settingsCardReadersTapped)
        guard let viewController = UIStoryboard.dashboard.instantiateViewController(ofClass: CardReaderSettingsViewController.self) else {
            fatalError("Cannot instantiate `CardReaderSettingsViewController` from Dashboard storyboard")
        }
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
        case .cardReaders:
            cardReadersWasPressed()
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
    case cardReaders
    case logout
    case privacy
    case betaFeatures
    case sendFeedback
    case about
    case licenses
    case deviceSettings
    case wormholy

    var type: UITableViewCell.Type {
        switch self {
        case .selectedStore:
            return HeadlineLabelTableViewCell.self
        case .switchStore:
            return BasicTableViewCell.self
        case .support:
            return BasicTableViewCell.self
        case .cardReaders:
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
        }
    }

    var reuseIdentifier: String {
        return type.reuseIdentifier
    }
}

// MARK: - Footer
//
private extension SettingsViewController {

    /// Returns the Settings Footer Attributed Text
    /// (which contains a link to the "Work with us" URL)
    ///
    var hiringAttributedText: NSAttributedString {
        let hiringText = NSLocalizedString("Made with love by Automattic. <a href=\"https://automattic.com/work-with-us/\">We’re hiring!</a>",
                                           comment: "It reads 'Made with love by Automattic. We’re hiring!'. Place \'We’re hiring!' between `<a>` and `</a>`"
        )
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
