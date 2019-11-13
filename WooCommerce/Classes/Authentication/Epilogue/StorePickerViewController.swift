import Foundation
import UIKit
import WordPressAuthenticator
import WordPressUI
import Yosemite


typealias SelectStoreClosure = () -> Void

/// StorePickerViewControllerDelegate: the interface with operations related to the store picker
///
protocol StorePickerViewControllerDelegate: AnyObject {

    /// Notifies the delegate that a store is about to be picked.
    ///
    /// - Parameter storeID: ID of the store selected by the user
    /// - Returns: a closure to be executed prior to store selection
    ///
    func willSelectStore(with storeID: Int, onCompletion: @escaping SelectStoreClosure)

    /// Notifies the delegate that the store selection is complete
    ///
    func didSelectStore(with storeID: Int)
}


/// Configuration option enum for the StorePickerViewController
///
enum StorePickerConfiguration {

    /// Setup the store picker for use in the login flow
    ///
    case login

    /// Setup the store picker for use in the store switching flow
    ///
    case switchingStores

    /// Setup the store picker for use as a basic modal in app
    ///
    case standard
}


/// Allows the user to pick which WordPress.com (OR) Jetpack-Connected-Store we should set up as the Main Store.
///
class StorePickerViewController: UIViewController {

    /// StorePickerViewController Delegate
    ///
    weak var delegate: StorePickerViewControllerDelegate?

    /// Selected configuration for the store picker
    ///
    var configuration: StorePickerConfiguration = .login

    // MARK: - Private Properties

    /// White-Background View, to be placed surrounding the bottom area.
    ///
    @IBOutlet private var actionBackgroundView: UIView! {
        didSet {
            actionBackgroundView.layer.masksToBounds = false
            actionBackgroundView.layer.shadowOpacity = StorePickerConstants.backgroundShadowOpacity
        }
    }

    /// Default Action Button.
    ///
    @IBOutlet private var actionButton: FancyAnimatedButton! {
        didSet {
            actionButton.backgroundColor = .clear
            actionButton.titleFont = StyleManager.actionButtonTitleFont
        }
    }

    /// Secondary Action Button.
    ///
    @IBOutlet private var secondaryActionButton: FancyAnimatedButton! {
        didSet {
            secondaryActionButton.backgroundColor = .clear
            secondaryActionButton.titleFont = StyleManager.actionButtonTitleFont
            secondaryActionButton.setTitle(NSLocalizedString("Try another account",
                                                             comment: "Button to trigger connection to another account in store picker"),
                                           for: .normal)
        }
    }

    /// No Results Placeholder Image
    ///
    @IBOutlet private var noResultsImageView: UIImageView!

    /// No Results Placeholder Text
    ///
    @IBOutlet private var noResultsLabel: UILabel! {
        didSet {
            noResultsLabel.font = StyleManager.subheadlineFont
            noResultsLabel.textColor = .textSubtle
        }
    }

    /// Main tableView
    ///
    @IBOutlet private var tableView: UITableView! {
        didSet {
            tableView.tableHeaderView = accountHeaderView
        }
    }

    /// Represents the internal StorePicker State
    ///
    private var state: StorePickerState = .empty {
        didSet {
            stateWasUpdated()
        }
    }

    /// Header View: Displays all of the Account Details
    ///
    private let accountHeaderView: AccountHeaderView = {
        return AccountHeaderView.instantiateFromNib()
    }()

    /// Site Picker's dedicated NoticePresenter (use this here instead of ServiceLocator.noticePresenter)
    ///
    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
    }()

    /// ResultsController: Loads Sites from the Storage Layer.
    ///
    private let resultsController: ResultsController<StorageSite> = {
        let storageManager = ServiceLocator.storageManager
        let predicate = NSPredicate(format: "isWooCommerceActive == YES")
        let descriptor = NSSortDescriptor(key: "name", ascending: true)

        return ResultsController(storageManager: storageManager, matching: predicate, sortedBy: [descriptor])
    }()

    /// Keep track of the (Autosizing Cell's) Height. This helps us prevent UI flickers, due to sizing recalculations.
    ///
    private var estimatedRowHeights = [IndexPath: CGFloat]()

    /// The currently selected site on this screen (NOT the current default site for the app).
    ///
    private var currentlySelectedSite: Site? {
        didSet {
            guard let site = currentlySelectedSite else {
                return
            }

            displaySiteWCRequirementWarningIfNeeded(siteID: site.siteID, siteName: site.name)
        }
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMainView()
        setupAccountHeader()
        setupTableView()
        refreshResults()

        switch configuration {
        case .login:
            startListeningToNotifications()
        case .switchingStores:
            secondaryActionButton.isHidden = true
        default:
            break
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupViewForCurrentConfiguration()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if configuration == .login {
            // This should be called here to address this issue:
            // https://github.com/woocommerce/woocommerce-ios/issues/693
            stopListeningToNotifications()
        }
    }
}


// MARK: - Setup Methods
//
private extension StorePickerViewController {

    func setupMainView() {
        view.backgroundColor = .listBackground
    }

    func setupTableView() {
        let cells = [
            EmptyStoresTableViewCell.reuseIdentifier: EmptyStoresTableViewCell.loadNib(),
            StoreTableViewCell.reuseIdentifier: StoreTableViewCell.loadNib()
        ]

        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }

        tableView.backgroundColor = .listBackground
    }

    func setupAccountHeader() {
        guard let defaultAccount = ServiceLocator.stores.sessionManager.defaultAccount else {
            return
        }

        accountHeaderView.username = "@" + defaultAccount.username
        accountHeaderView.fullname = defaultAccount.displayName
        accountHeaderView.downloadGravatar(with: defaultAccount.email)
        accountHeaderView.isHelpButtonEnabled = configuration == .login
        accountHeaderView.onHelpRequested = { ServiceLocator.authenticationManager.presentSupport(from: self, sourceTag: .generalLogin) }
    }

    func setupNavigation() {
        title = NSLocalizedString("Select Store", comment: "Page title for the select a different store screen")
        let dismissLiteral = NSLocalizedString("Dismiss", comment: "Dismiss button in store picker")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: dismissLiteral,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(cleanupAndDismiss))
    }

    func setupViewForCurrentConfiguration() {
        guard isViewLoaded else {
            return
        }

        switch configuration {
        case .switchingStores:
            setupNavigation()
        default:
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

    func refreshResults() {
        try? resultsController.performFetch()
        ServiceLocator.analytics.track(.sitePickerStoresShown, withProperties: ["num_of_stores": resultsController.numberOfObjects])
        state = StorePickerState(sites: resultsController.fetchedObjects)
    }

    func stateWasUpdated() {
        preselectStoreIfPossible()
        reloadInterface()
    }
}


// MARK: - Notifications
//
extension StorePickerViewController {

    /// Wires all of the Notification Hooks
    ///
    func startListeningToNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(applicationTerminating), name: .applicationTerminating, object: nil)
    }

    /// Stops listening to all related Notifications
    ///
    func stopListeningToNotifications() {
        NotificationCenter.default.removeObserver(self)
    }

    /// Runs whenever the application is about to terminate.
    ///
    @objc func applicationTerminating() {
        guard ServiceLocator.stores.isAuthenticated else {
            return
        }

        // If we are on this screen and the app is about to terminate, it means a default store
        // was never selected so force the user to go through the auth flow again.
        //
        // For more deets, see: https://github.com/woocommerce/woocommerce-ios/issues/466
        ServiceLocator.stores.deauthenticate()
    }
}


// MARK: - Convenience Methods
//
private extension StorePickerViewController {

    /// Sets the first available Store as the default one. If possible!
    ///
    func preselectStoreIfPossible() {
        guard case let .available(sites) = state, let firstSite = sites.first else {
            return
        }
        guard currentlySelectedSite == nil else {
            return
        }

        // If a site address was passed in credentials, select it
        if let siteAddress = ServiceLocator.stores.sessionManager.defaultCredentials?.siteAddress,
            let site = sites.filter({ $0.url == siteAddress }).first {
            currentlySelectedSite = site
            return
        }

        // If there is a defaultSite already set, select it
        if let site = ServiceLocator.stores.sessionManager.defaultSite {
            currentlySelectedSite = site
            return
        }

        // Otherwise select the first site in the list
        currentlySelectedSite = firstSite
    }

    /// Reloads the UI.
    ///
    func reloadInterface() {
        actionButton.setTitle(state.actionTitle, for: .normal)
        switch state {
        case .empty:
            updateActionButtonAndTableState(animating: false, enabled: false)
        default:
            break
        }

        tableView.separatorStyle = state.separatorStyle
        tableView.reloadData()
    }

    /// Dismiss this VC
    ///
    @objc func cleanupAndDismiss() {
        if let siteID = currentlySelectedSite?.siteID {
            delegate?.didSelectStore(with: siteID)
        }

        switch configuration {
        case .switchingStores:
            dismiss(animated: true)
        default:
            dismiss(animated: true)
        }
    }

    /// Toggles the dismiss button, if it exists
    ///
    func toggleDismissButton(enabled: Bool) {
        guard let dismissButton = navigationItem.leftBarButtonItem else {
            return
        }

        dismissButton.isEnabled = enabled
    }

    /// This method will reload the [Selected Row]
    ///
    func reloadSelectedStoreRows(afterRunning block: () -> Void) {
        /// Preserve: Selected and Checked Rows
        ///
        var rowsToReload = [IndexPath]()

        if let oldSiteID = currentlySelectedSite?.siteID,
            let oldCheckedRow = state.indexPath(for: oldSiteID) {
            rowsToReload.append(oldCheckedRow)
        }

        if let oldSelectedRow = tableView.indexPathForSelectedRow {
            rowsToReload.append(oldSelectedRow)
        }

        /// Update the Default Store
        ///
        block()

        if let newSiteID = currentlySelectedSite?.siteID,
            let selectedRow = state.indexPath(for: newSiteID) {
            rowsToReload.append(selectedRow)
        }

        /// Refresh: Selected and Checked Rows
        ///
        tableView.reloadRows(at: rowsToReload, with: .none)
    }

    /// Re-initializes the Login Flow, forcing a logout. This may be required if the WordPress.com Account has no Stores available.
    ///
    func restartAuthentication() {
        guard ServiceLocator.stores.needsDefaultStore else {
            return
        }

        let loginViewController = ServiceLocator.authenticationManager.loginForWordPressDotCom()

        guard let navigationController = navigationController else {
            assertionFailure("Navigation error: one of the login / logout states is not correctly handling navigation. No navigationController found.")
            return
        }

        ServiceLocator.stores.deauthenticate()
        navigationController.setViewControllers([loginViewController], animated: true)
    }

    /// If the provided site's WC version is not valid, display a warning to the user.
    ///
    func displaySiteWCRequirementWarningIfNeeded(siteID: Int, siteName: String) {
        updateActionButtonAndTableState(animating: true, enabled: false)
        RequirementsChecker.checkMinimumWooVersion(for: siteID) { [weak self] (result, error) in
            switch result {
            case .validWCVersion:
                self?.updateUIForValidSite()
            case .invalidWCVersion:
                self?.updateUIForInvalidSite(named: siteName)
            case .empty, .error:
                self?.updateUIForEmptyOrErroredSite(named: siteName, with: siteID)
            }
        }
    }

    /// Update the UI upon receiving a response for a valid WC site
    ///
    func updateUIForValidSite() {
        toggleDismissButton(enabled: true)
        updateActionButtonAndTableState(animating: false, enabled: true)
    }

    /// Update the UI upon receiving a response for an invalid WC site
    ///
    func updateUIForInvalidSite(named siteName: String) {
        toggleDismissButton(enabled: false)
        switch state {
        case .empty:
            updateUIForNoSitesFound(named: siteName)
        default:
            updateUIForInvalidSiteFound(named: siteName)
        }
    }

    /// Update the UI upon receiving an error or empty response instead of site info
    ///
    func updateUIForEmptyOrErroredSite(named siteName: String, with siteID: Int) {
        toggleDismissButton(enabled: false)
        updateActionButtonAndTableState(animating: false, enabled: false)
        displayVersionCheckErrorNotice(siteID: siteID, siteName: siteName)
    }

    /// Little helper func that helps manage the actionButton and Table state while checking on a
    /// site's WC requirements.
    ///
    func updateActionButtonAndTableState(animating: Bool, enabled: Bool) {
        actionButton.isEnabled = enabled
        actionButton.showActivityIndicator(animating)

        // Wait till the requirement check is complete before allowing the user to select another store
        tableView.allowsSelection = !animating
    }

    /// Update the UI when the user has a valid login but no WC sites.
    ///
    func updateUIForNoSitesFound(named siteName: String) {
        hideActionButton()
        displayFancyWCRequirementAlert(siteName: siteName)
    }

    /// Update the UI when the user has a valid login
    /// but the currently selected WC site is not valid.
    ///
    func updateUIForInvalidSiteFound(named siteName: String) {
        updateActionButtonAndTableState(animating: false, enabled: false)
        displayFancyWCRequirementAlert(siteName: siteName)
    }

    /// Helper function that hides the "Continue" action button
    /// upon finding a valid WP login and no valid WC sites.
    func hideActionButton() {
        actionButton.isHidden = true
        actionButton.showActivityIndicator(false)
    }

    /// Displays the Error Notice for the version check.
    ///
    func displayVersionCheckErrorNotice(siteID: Int, siteName: String) {
        let message = String.localizedStringWithFormat(
            NSLocalizedString(
                "Unable to successfully connect to %@",
                comment: "On the site picker screen, the error displayed when connecting to a site fails. " +
                "It reads: Unable to successfully connect to {site name}"
            ),
            siteName
        )
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: message, feedbackType: .error, actionTitle: actionTitle) { [weak self] in
            self?.displaySiteWCRequirementWarningIfNeeded(siteID: siteID, siteName: siteName)
        }

        noticePresenter.enqueue(notice: notice)
    }

    /// Displays the Fancy Alert notice for a failed WC requirement check
    ///
    func displayFancyWCRequirementAlert(siteName: String) {
        let fancyAlert = FancyAlertViewController.makewWooUpgradeAlertControllerForSitePicker(siteName: siteName)
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        present(fancyAlert, animated: true)
    }
}


// MARK: - Action Handlers
//
extension StorePickerViewController {

    /// Proceeds with the Login Flow.
    ///
    @IBAction func actionWasPressed() {
        switch state {
        case .empty:
            restartAuthentication()
        default:
            guard let delegate = delegate else {
                return
            }
            guard let site = currentlySelectedSite else {
                return
            }

            delegate.willSelectStore(with: site.siteID) { [weak self] in
                self?.cleanupAndDismiss()
            }
        }
    }

    /// Proceeds with the Logout Flow.
    ///
    @IBAction func secondaryActionWasPressed() {
        restartAuthentication()
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension StorePickerViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return state.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return state.numberOfRows
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return state.headerTitle?.uppercased()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let site = state.site(at: indexPath) else {
            hideActionButton()
            return tableView.dequeueReusableCell(withIdentifier: EmptyStoresTableViewCell.reuseIdentifier, for: indexPath)
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: StoreTableViewCell.reuseIdentifier, for: indexPath) as? StoreTableViewCell else {
            fatalError()
        }

        cell.name = site.name
        cell.url = site.url
        cell.allowsCheckmark = state.multipleStoresAvailable
        cell.displaysCheckmark = currentlySelectedSite == site

        return cell
    }
}


// MARK: - UITableViewDelegate Conformance
//
extension StorePickerViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return estimatedRowHeights[indexPath] ?? StorePickerConstants.estimatedRowHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard state.multipleStoresAvailable else {
            // If we only have a single store available, don't allow the row to be selected
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let site = state.site(at: indexPath) else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        reloadSelectedStoreRows() {
            currentlySelectedSite = site
        }

        tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {

        // Preserve the Cell Height
        // Why: Because Autosizing Cells, upon reload, will need to be laid out yet again. This might cause
        // UI glitches / unwanted animations. By preserving it, *then* the estimated will be extremely close to
        // the actual value. AKA no flicker!
        //
        estimatedRowHeights[indexPath] = cell.frame.height
    }
}


// MARK: - StorePickerConstants: Contains all of the constants required by the Picker.
//
private enum StorePickerConstants {
    static let backgroundShadowOpacity = Float(0.2)
    static let numberOfSections = 1
    static let emptyStateRowCount = 1
    static let estimatedRowHeight = CGFloat(50)
}


// MARK: - Represents the StorePickerViewController's Internal State.
//
private enum StorePickerState {

    /// No Stores onScreen
    ///
    case empty

    /// Stores Available!
    ///
    case available(sites: [Yosemite.Site])


    /// Designated Initializer
    ///
    init(sites: [Yosemite.Site]) {
        if sites.isEmpty {
            self = .empty
        } else {
            self = .available(sites: sites)
        }
    }
}


// MARK: - StorePickerState Properties
//
private extension StorePickerState {

    /// Action Button's Title
    ///
    var actionTitle: String {
            return NSLocalizedString("Continue", comment: "")
    }

    /// Results Table's Header Title
    ///
    var headerTitle: String? {
        switch self {
        case .empty:
            return nil
        case .available(let sites) where sites.count > 1:
            return NSLocalizedString("Pick Store to Connect", comment: "Store Picker's Section Title: Displayed whenever there are multiple Stores.")
        default:
            return NSLocalizedString("Connected Store", comment: "Store Picker's Section Title: Displayed when there's a single pre-selected Store.")
        }
    }

    /// Indicates if there is more than one Store.
    ///
    var multipleStoresAvailable: Bool {
        return numberOfRows > 1
    }

    /// Number of TableView Sections
    ///
    var numberOfSections: Int {
        return StorePickerConstants.numberOfSections
    }

    /// Number of TableView Rows
    ///
    var numberOfRows: Int {
        switch self {
        case .available(let sites):
            return sites.count
        default:
            return StorePickerConstants.emptyStateRowCount
        }
    }

    /// Results Table's Separator Style
    ///
    var separatorStyle: UITableViewCell.SeparatorStyle {
        switch self {
        case .empty:
            return .none
        default:
            return .singleLine
        }
    }

    /// Returns the site to be displayed at a given IndexPath
    ///
    func site(at indexPath: IndexPath) -> Yosemite.Site? {
        switch self {
        case .empty:
            return nil
        case .available(let sites):
            return sites[indexPath.row]
        }
    }

    /// Returns the IndexPath for the specified Site.
    ///
    func indexPath(for siteID: Int) -> IndexPath? {
        guard case let .available(sites) = self else {
            return nil
        }

        guard let row = sites.firstIndex(where: { $0.siteID == siteID }) else {
            return nil
        }

        return IndexPath(row: row, section: 0)
    }
}
