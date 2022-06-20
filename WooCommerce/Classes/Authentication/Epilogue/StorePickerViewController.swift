import Foundation
import SafariServices
import UIKit
import WordPressAuthenticator
import WordPressUI
import Yosemite
import Experiments


typealias SelectStoreClosure = () -> Void

/// StorePickerViewControllerDelegate: the interface with operations related to the store picker
///
protocol StorePickerViewControllerDelegate: AnyObject {

    /// Notifies the delegate that the store selection is complete,
    /// - Parameter storeID: ID of the store selected by the user
    /// - Returns: a closure to be executed after the store selection
    ///
    func didSelectStore(with storeID: Int64, onCompletion: @escaping SelectStoreClosure)

    /// Notifies the delegate to dismiss the store picker and restart authentication.
    func restartAuthentication()
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

    /// Setup the store picker for use as list of stores
    ///
    case listStores
}


/// Allows the user to pick which WordPress.com (OR) Jetpack-Connected-Store we should set up as the Main Store.
///
final class StorePickerViewController: UIViewController {

    /// StorePickerViewController Delegate
    ///
    weak var delegate: StorePickerViewControllerDelegate?

    /// Selected configuration for the store picker
    ///
    var configuration: StorePickerConfiguration = .login

    // MARK: - Private Properties

    /// Default Action Button.
    ///
    @IBOutlet private var actionButton: FancyAnimatedButton! {
        didSet {
            actionButton.backgroundColor = .clear
            actionButton.titleFont = StyleManager.actionButtonTitleFont
            actionButton.accessibilityIdentifier = "login-epilogue-continue-button"
        }
    }

    /// Secondary Action Button.
    ///
    @IBOutlet private var secondaryActionButton: FancyAnimatedButton! {
        didSet {
            secondaryActionButton.backgroundColor = .clear
            secondaryActionButton.titleFont = StyleManager.actionButtonTitleFont
            secondaryActionButton.setTitle(NSLocalizedString("Try With Another Account",
                                                             comment: "Button to trigger connection to another account in store picker"),
                                           for: .normal)
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

    private lazy var removeAppleIDAccessCoordinator: RemoveAppleIDAccessCoordinator =
    RemoveAppleIDAccessCoordinator(sourceViewController: self) { [weak self] in
        guard let self = self else { return .failure(RemoveAppleIDAccessError.presenterDeallocated) }
        return await self.removeAppleIDAccess()
    } onRemoveSuccess: { [weak self] in
        self?.restartAuthentication()
    }

    private let appleIDCredentialChecker: AppleIDCredentialCheckerProtocol
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService

    init(appleIDCredentialChecker: AppleIDCredentialCheckerProtocol = AppleIDCredentialChecker(),
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.appleIDCredentialChecker = appleIDCredentialChecker
        self.stores = stores
        self.featureFlagService = featureFlagService
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            startABTesting()
        case .switchingStores:
            secondaryActionButton.isHidden = true
        case .listStores:
            hideActionButtons()
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
        view.backgroundColor = backgroundColor()
    }

    func setupTableView() {
        tableView.registerNib(for: EmptyStoresTableViewCell.self)
        tableView.registerNib(for: StoreTableViewCell.self)
        tableView.backgroundColor = backgroundColor()
    }

    func setupAccountHeader() {
        guard let defaultAccount = ServiceLocator.stores.sessionManager.defaultAccount else {
            return
        }

        accountHeaderView.username = "@" + defaultAccount.username
        accountHeaderView.fullname = defaultAccount.displayName
        accountHeaderView.downloadGravatar(with: defaultAccount.email)
        accountHeaderView.isHelpButtonEnabled = configuration == .login || configuration == .standard
        accountHeaderView.onHelpRequested = { [weak self] in
            guard let self = self else {
                return
            }
            self.presentHelp()
        }
    }

    func setupNavigation() {
        title = NSLocalizedString("Select Store", comment: "Page title for the select a different store screen")
        let dismissLiteral = NSLocalizedString("Dismiss", comment: "Dismiss button in store picker")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: dismissLiteral,
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(dismissStorePicker))
    }

    func setupNavigationForListOfConnectedStores() {
        title = NSLocalizedString("Connected Stores", comment: "Page title for the list of connected stores")
    }

    func hideActionButtons() {
        actionButton.isHidden = true
        secondaryActionButton.isHidden = true
    }

    func setupViewForCurrentConfiguration() {
        guard isViewLoaded else {
            return
        }

        switch configuration {
        case .switchingStores:
            setupNavigation()
        case .listStores:
            hideActionButtons()
            setupNavigationForListOfConnectedStores()
        default:
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

    func refreshResults() {
        refetchSitesAndUpdateState()
        ServiceLocator.analytics.track(.sitePickerStoresShown, withProperties: ["num_of_stores": resultsController.numberOfObjects])

        synchronizeSites { [weak self] _ in
            self?.refetchSitesAndUpdateState()
        }
    }

    func refetchSitesAndUpdateState() {
        try? resultsController.performFetch()
        state = StorePickerState(sites: resultsController.fetchedObjects)
    }

    func stateWasUpdated() {
        preselectStoreIfPossible()
        reloadInterface()
    }

    func backgroundColor() -> UIColor {
        return WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor ?? .listBackground
    }

    func presentHelp() {
        ServiceLocator.authenticationManager.presentSupport(from: self, sourceTag: .generalLogin)
    }
}

// MARK: - Syncing
//
private extension StorePickerViewController {
    func synchronizeSites(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let syncStartTime = Date()
        let isJetpackConnectionPackageSupported = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.jetpackConnectionPackageSupport)
        let action = AccountAction
            .synchronizeSites(selectedSiteID: currentlySelectedSite?.siteID,
                              isJetpackConnectionPackageSupported: isJetpackConnectionPackageSupported) { result in
                switch result {
                case .success(let containsJCPSites):
                    if containsJCPSites {
                        let syncDuration = round(Date().timeIntervalSince(syncStartTime) * 1000)
                        ServiceLocator.analytics.track(.jetpackCPSitesFetched, withProperties: ["duration": syncDuration])
                    }
                    onCompletion(.success(()))
                case .failure(let error):
                    onCompletion(.failure(error))
                }
            }
        ServiceLocator.stores.dispatch(action)
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
        guard configuration != .listStores else {
            return
        }

        guard case let .available(sites) = state, let firstSite = sites.first else {
            return
        }
        guard currentlySelectedSite == nil else {
            return
        }

        // If there is a defaultSite already set, select it
        if let site = ServiceLocator.stores.sessionManager.defaultSite {
            currentlySelectedSite = site
            return
        }

        // If a site address was passed in credentials, select it
        if let siteAddress = ServiceLocator.stores.sessionManager.defaultCredentials?.siteAddress,
            let site = sites.filter({ $0.url == siteAddress }).first {
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
    @objc func dismissStorePicker() {
        dismiss()
    }

    func dismiss() {
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

        delegate?.restartAuthentication()
    }

    /// If the provided site's WC version is not valid, display a warning to the user.
    ///
    func displaySiteWCRequirementWarningIfNeeded(siteID: Int64, siteName: String) {
        updateActionButtonAndTableState(animating: true, enabled: false)
        RequirementsChecker.checkMinimumWooVersion(for: siteID) { [weak self] result in
            switch result {
            case .success(.validWCVersion):
                self?.updateUIForValidSite()
            case .success(.invalidWCVersion):
                self?.updateUIForInvalidSite(named: siteName)
            case .failure:
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
    func updateUIForEmptyOrErroredSite(named siteName: String, with siteID: Int64) {
        toggleDismissButton(enabled: false)
        updateActionButtonAndTableState(animating: false, enabled: false)
        displayUnknownErrorModal()
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

    /// Displays a generic error view as a modal with options to see troubleshooting tips and to contact support.
    ///
    func displayUnknownErrorModal() {
        let viewController = StorePickerErrorHostingController.createWithActions(presenting: self)
        viewController.modalPresentationStyle = .custom
        viewController.transitioningDelegate = self
        present(viewController, animated: true)
    }

    /// Displays the Fancy Alert notice for a failed WC requirement check
    ///
    func displayFancyWCRequirementAlert(siteName: String) {
        let fancyAlert = FancyAlertViewController.makewWooUpgradeAlertControllerForSitePicker(siteName: siteName)
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        present(fancyAlert, animated: true)
    }

    /// Refreshes the AB testing assignments (refresh is needed after a user logs in)
    ///
    func startABTesting() {
        guard ServiceLocator.stores.isAuthenticated else {
            return
        }
        ABTest.start()
    }
}

// MARK: Transition Controller Delegate
extension StorePickerViewController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController,
                                presenting: UIViewController?,
                                source: UIViewController) -> UIPresentationController? {
        ModalHostingPresentationController(presentedViewController: presented, presenting: presenting)
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

            delegate.didSelectStore(with: site.siteID) { [weak self] in
                self?.dismiss()
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
        guard configuration != .listStores else {
            return nil
        }

        return state.headerTitle?.uppercased()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let site = state.site(at: indexPath) else {
            hideActionButton()
            let cell = tableView.dequeueReusableCell(EmptyStoresTableViewCell.self, for: indexPath)
            cell.onJetpackSetupButtonTapped = { [weak self] in
                guard let self = self else { return }

                WebviewHelper.launch(WooConstants.URLs.emptyStoresJetpackSetup.asURL(), with: self)
            }
            let isRemoveAppleIDAccessButtonVisible = appleIDCredentialChecker.hasAppleUserID()
            && featureFlagService.isFeatureFlagEnabled(.appleIDAccountDeletion)
            cell.updateRemoveAppleIDAccessButtonVisibility(isVisible: isRemoveAppleIDAccessButtonVisible)
            if isRemoveAppleIDAccessButtonVisible {
                cell.onRemoveAppleIDAccessButtonTapped = { [weak self] in
                    guard let self = self else { return }
                    self.removeAppleIDAccessCoordinator.start()
                }
            }
            return cell
        }
        let cell = tableView.dequeueReusableCell(StoreTableViewCell.self, for: indexPath)

        cell.name = site.name
        cell.url = site.url
        cell.allowsCheckmark = state.multipleStoresAvailable
        cell.displaysCheckmark = currentlySelectedSite?.siteID == site.siteID

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
        guard state.multipleStoresAvailable && configuration != .listStores else {
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

private extension StorePickerViewController {
    func removeAppleIDAccess() async -> Result<Void, Error> {
        await withCheckedContinuation { [weak self] continuation in
            guard let self = self else { return }
            guard let credentials = self.stores.sessionManager.defaultCredentials else {
                return continuation.resume(returning: .failure(RemoveAppleIDAccessError.noCredentials))
            }
            let action = AccountAction.removeAppleIDAccess(dotcomAppID: ApiCredentials.dotcomAppId,
                                                           dotcomSecret: ApiCredentials.dotcomSecret,
                                                           authToken: credentials.authToken) { result in
                continuation.resume(returning: result)
            }
            self.stores.dispatch(action)
        }
    }
}

// MARK: - StorePickerConstants: Contains all of the constants required by the Picker.
//
private enum StorePickerConstants {
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
    func indexPath(for siteID: Int64) -> IndexPath? {
        guard case let .available(sites) = self else {
            return nil
        }

        guard let row = sites.firstIndex(where: { $0.siteID == siteID }) else {
            return nil
        }

        return IndexPath(row: row, section: 0)
    }
}
