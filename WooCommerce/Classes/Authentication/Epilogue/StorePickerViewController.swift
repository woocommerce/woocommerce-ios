import Combine
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

    /// Shows a Role Error page using the provided error information.
    /// The error page is pushed to the navigation stack so the user is not locked out, and can go back to select another store.
    ///
    func showRoleErrorScreen(for siteID: Int64, errorInfo: StorageEligibilityErrorInfo, onCompletion: @escaping SelectStoreClosure)

    /// Notifies the delegate to dismiss the store picker and restart authentication.
    func restartAuthentication()

    /// Notifies the delegate to create a store.
    func createStore()
}


/// Configuration option enum for the StorePickerViewController
///
enum StorePickerConfiguration: Equatable {

    /// Setup the store picker for use in the login flow
    ///
    case login

    /// Setup the store picker for store creation initiated from the logged out state
    ///
    case storeCreationFromLogin(source: LoggedOutStoreCreationCoordinator.Source)

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
    private let configuration: StorePickerConfiguration

    /// View model for the controller
    ///
    private let viewModel: StorePickerViewModel

    private var stateSubscription: AnyCancellable?

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
            secondaryActionButton.setTitle(Localization.tryAnotherAccount, for: .normal)
        }
    }

    /// Enter site address / Add Store Button.
    ///
    @IBOutlet private var addStoreButton: FancyAnimatedButton! {
        didSet {
            addStoreButton.backgroundColor = .clear
            addStoreButton.titleFont = StyleManager.actionButtonTitleFont
            addStoreButton.setTitle(Localization.addStoreButton, for: .normal)
        }
    }

    /// Main tableView
    ///
    @IBOutlet private var tableView: UITableView! {
        didSet {
            tableView.tableHeaderView = accountHeaderView
        }
    }

    /// Header View: Displays all of the Account Details
    ///
    private let accountHeaderView: AccountHeaderView = {
        AccountHeaderView.instantiateFromNib()
    }()

    private lazy var addStoreFooterView: AddStoreFooterView = {
       AddStoreFooterView(addStoreHandler: { [weak self] in
           guard let self else { return }
           ServiceLocator.analytics.track(.sitePickerAddStoreTapped)
           self.presentAddStoreActionSheet(from: self.addStoreFooterView)
       })
    }()

    /// Site Picker's dedicated NoticePresenter (use this here instead of ServiceLocator.noticePresenter)
    ///
    private lazy var noticePresenter: DefaultNoticePresenter = {
        let noticePresenter = DefaultNoticePresenter()
        noticePresenter.presentingViewController = self
        return noticePresenter
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

    private lazy var closeAccountCoordinator: CloseAccountCoordinator =
    CloseAccountCoordinator(sourceViewController: self) { [weak self] in
        guard let self = self else { throw CloseAccountError.presenterDeallocated }
        return try await self.closeAccount()
    } onRemoveSuccess: { [weak self] in
        self?.restartAuthentication()
    }

    private var storeCreationCoordinator: StoreCreationCoordinator?

    private let appleIDCredentialChecker: AppleIDCredentialCheckerProtocol
    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let isStoreCreationEnabled: Bool

    init(configuration: StorePickerConfiguration,
         appleIDCredentialChecker: AppleIDCredentialCheckerProtocol = AppleIDCredentialChecker(),
         stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.configuration = configuration
        self.appleIDCredentialChecker = appleIDCredentialChecker
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.viewModel = StorePickerViewModel(configuration: configuration)
        self.isStoreCreationEnabled = featureFlagService.isFeatureFlagEnabled(.storeCreationMVP)
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
        observeStateChange()

        switch configuration {
        case .login:
            startListeningToNotifications()
        case .switchingStores:
            secondaryActionButton.isHidden = true
        default:
            break
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableView.updateHeaderHeight()
        tableView.updateFooterHeight()
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
        tableView.sectionFooterHeight = 0
    }

    func setupAccountHeader() {
        guard let defaultAccount = ServiceLocator.stores.sessionManager.defaultAccount else {
            return
        }

        accountHeaderView.email = defaultAccount.email
        accountHeaderView.downloadGravatar(with: defaultAccount.email)
        let showsActionButton: Bool = {
            switch configuration {
            case .login, .standard, .storeCreationFromLogin:
                return true
            case .switchingStores, .listStores:
                return false
            }
        }()
        accountHeaderView.isActionButtonEnabled = showsActionButton
        accountHeaderView.onActionButtonTapped = { [weak self] sourceView in
            guard let self else { return }
            self.presentActionMenu(from: sourceView)
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

    func setupViewForCurrentConfiguration() {
        guard isViewLoaded else {
            return
        }

        switch configuration {
        case .switchingStores:
            setupNavigation()
        case .listStores:
            setupNavigationForListOfConnectedStores()
        default:
            navigationController?.setNavigationBarHidden(true, animated: true)
        }
    }

    func refreshResults() {
        viewModel.refreshSites(currentlySelectedSiteID: currentlySelectedSite?.siteID)
        viewModel.trackScreenView()
    }

    func observeStateChange() {
        stateSubscription = viewModel.$state.sink { [weak self] _ in
            guard let self = self else { return }
            self.preselectStoreIfPossible()
            self.reloadInterface()
            self.updateFooterViewIfNeeded()
        }
    }

    func backgroundColor() -> UIColor {
        return WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor ?? .listBackground
    }

    func presentActionMenu(from sourceView: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        let logOutAction = UIAlertAction(title: Localization.ActionMenu.logOut, style: .default) { [weak self] _ in
            self?.restartAuthentication()
        }
        actionSheet.addAction(logOutAction)

        let helpAction = UIAlertAction(title: Localization.ActionMenu.help, style: .default) { [weak self] _ in
            guard let self else { return }
            ServiceLocator.analytics.track(.sitePickerHelpButtonTapped)
            self.presentHelp()
        }
        actionSheet.addAction(helpAction)

        let isCloseAccountButtonVisible: Bool = {
            let hasEmptyStores: Bool = {
                if case .empty = viewModel.state {
                    return true
                }
                return false
            }()
            return (appleIDCredentialChecker.hasAppleUserID()
                    || featureFlagService.isFeatureFlagEnabled(.storeCreationMVP)
                    || featureFlagService.isFeatureFlagEnabled(.storeCreationM2)) && hasEmptyStores
        }()
        if isCloseAccountButtonVisible {
            let closeAccountAction = UIAlertAction(title: Localization.ActionMenu.closeAccount, style: .destructive) { [weak self] _ in
                guard let self else { return }
                ServiceLocator.analytics.track(event: .closeAccountTapped(source: .emptyStores))
                self.closeAccountCoordinator.start()
            }
            actionSheet.addAction(closeAccountAction)
        }

        let cancelAction = UIAlertAction(title: Localization.cancel, style: .cancel)
        actionSheet.addAction(cancelAction)

        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
        }

        present(actionSheet, animated: true)
    }

    func presentHelp() {
        ServiceLocator.authenticationManager.presentSupport(from: self, screen: .storePicker)
    }

    func presentAddStoreActionSheet(from view: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text
        let createStoreAction = UIAlertAction(title: Localization.createStore, style: .default) { [weak self] _ in
            // TODO: add tracks for site creation
            self?.createStoreButtonPressed()
        }
        let addExistingStoreAction = UIAlertAction(title: Localization.connectExistingStore, style: .default) { [weak self] _ in
            ServiceLocator.analytics.track(.sitePickerConnectExistingStoreTapped)
            self?.presentSiteDiscovery()
        }
        let cancelAction = UIAlertAction(title: Localization.cancel, style: .cancel)

        actionSheet.addAction(createStoreAction)
        actionSheet.addAction(addExistingStoreAction)
        actionSheet.addAction(cancelAction)

        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = view.bounds
        }

        present(actionSheet, animated: true)
    }

    func presentSiteDiscovery() {
        guard let viewController = WordPressAuthenticator.siteDiscoveryUI() else {
            return
        }
        navigationController?.show(viewController, sender: nil)
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

        guard case let .available(sites) = viewModel.state, let firstSite = sites.first(where: { $0.isWooCommerceActive }) else {
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
        if case let .wpcom(_, _, siteAddress) = ServiceLocator.stores.sessionManager.defaultCredentials,
           let site = sites.filter({ $0.url == siteAddress }).first,
           site.isWooCommerceActive {
            currentlySelectedSite = site
            return
        }

        // Otherwise select the first site in the list
        currentlySelectedSite = firstSite
    }

    /// Reloads the UI.
    ///
    func reloadInterface() {
        actionButton.setTitle(Localization.continueButton, for: .normal)
        switch viewModel.state {
        case .empty:
            updateActionButtonAndTableState(animating: false, enabled: false)
            addStoreButton.isHidden = false
            secondaryActionButton.isHidden = true
        case .available(let sites):
            addStoreButton.isHidden = true
            if sites.allSatisfy({ $0.isWooCommerceActive == false }) {
                updateActionButtonAndTableState(animating: false, enabled: false)
            }
        }

        tableView.separatorStyle = viewModel.separatorStyle
        tableView.reloadData()
    }

    /// Shows the Add a Store button at the end of the store list if possible
    ///
    func updateFooterViewIfNeeded() {
        switch viewModel.state {
        case .available:
            tableView.tableFooterView = addStoreFooterView
        case .empty:
            tableView.tableFooterView = UIView()
        }
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

    /// Re-initializes the Login Flow, forcing a logout. This may be required if the WordPress.com Account has no Stores available.
    ///
    func restartAuthentication() {
        guard ServiceLocator.stores.needsDefaultStore else {
            return
        }

        ServiceLocator.analytics.track(.sitePickerLogoutButtonTapped)

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
        switch viewModel.state {
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
        addStoreButton.isHidden = false
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
private extension StorePickerViewController {

    /// Proceeds with the Login Flow.
    ///
    @IBAction func actionWasPressed() {
        switch viewModel.state {
        case .empty:
            restartAuthentication()
        default:
            guard let site = currentlySelectedSite else {
                return
            }

            checkRoleEligibility(for: site)
        }
    }

    /// Presents a screen to enter a store address to connect,
    /// or the add store action sheet for simplified login.
    ///
    @IBAction private func addStoreWasPressed() {
        if featureFlagService.isFeatureFlagEnabled(.storeCreationMVP) {
            ServiceLocator.analytics.track(.sitePickerAddStoreTapped)
            presentAddStoreActionSheet(from: addStoreButton)
        } else {
            ServiceLocator.analytics.track(.sitePickerConnectExistingStoreTapped)
            presentSiteDiscovery()
        }
    }

    /// Proceeds with the Logout Flow.
    ///
    @IBAction func secondaryActionWasPressed() {
        restartAuthentication()
    }

    func createStoreButtonPressed() {
        let source: WooAnalyticsEvent.StoreCreation.StorePickerSource = {
            switch configuration {
            case .switchingStores:
                return .switchStores
            case .login, .standard:
                return .login
            case .storeCreationFromLogin(let loggedOutSource):
                switch loggedOutSource {
                case .prologue:
                    return .loginPrologue
                case .loginEmailError:
                    return .other
                }
            default:
                return .other
            }
        }()
        ServiceLocator.analytics.track(event: .StoreCreation.sitePickerCreateSiteTapped(source: source))

        delegate?.createStore()
    }
}


// MARK: - UITableViewDataSource Conformance
//
extension StorePickerViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRows(inSection: section)
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return viewModel.titleForSection(at: section)?.uppercased()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let site = viewModel.site(at: indexPath) else {
            hideActionButton()
            let cell = tableView.dequeueReusableCell(EmptyStoresTableViewCell.self, for: indexPath)
            return cell
        }
        let cell = tableView.dequeueReusableCell(StoreTableViewCell.self, for: indexPath)

        cell.name = site.name
        cell.url = site.url
        cell.allowsCheckmark = viewModel.multipleStoresAvailable && site.isWooCommerceActive
        cell.displaysCheckmark = currentlySelectedSite?.siteID == site.siteID && site.isWooCommerceActive
        cell.displaysNotice = site.isWooCommerceActive == false

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
        guard viewModel.multipleStoresAvailable else {
            // If we only have a single store available, don't allow the row to be selected
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let site = viewModel.site(at: indexPath) else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }

        guard site.isWooCommerceActive else {
            let isNonAtomicSite = !site.isJetpackConnected
            ServiceLocator.analytics.track(.sitePickerNonWooSiteTapped, withProperties: ["is_non_atomic": isNonAtomicSite])

            if isNonAtomicSite {
                showNonAtomicSiteError(for: site)
            } else {
                showNoWooError(for: site)
            }

            return tableView.deselectRow(at: indexPath, animated: true)
        }

        currentlySelectedSite = site
        tableView.reloadData()
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
    func closeAccount() async throws {
        try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else { return }
            let action = AccountAction.closeAccount { result in
                continuation.resume(with: result)
            }
            self.stores.dispatch(action)
        }
    }

    func showNonAtomicSiteError(for site: Site) {
        let viewModel = NonAtomicSiteViewModel(site: site, stores: stores)
        let errorController = ULErrorViewController(viewModel: viewModel)
        navigationController?.show(errorController, sender: nil)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func showNoWooError(for site: Site) {
        let viewModel = NoWooErrorViewModel(
            site: site,
            showsConnectedStores: false, // avoid looping from store picker > no woo > store picker
            onSetupCompletion: { [weak self] siteID in
                guard let self = self else { return }
                self.navigationController?.popViewController(animated: true)
                self.viewModel.refreshSites(currentlySelectedSiteID: siteID)
                self.delegate?.didSelectStore(with: siteID) { [weak self] in
                    self?.dismiss()
                }
        })
        let noWooUI = ULErrorViewController(viewModel: viewModel)
        navigationController?.show(noWooUI, sender: nil)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }

    func checkRoleEligibility(for site: Site) {
        guard let delegate = delegate else {
            return
        }

        updateActionButtonAndTableState(animating: true, enabled: false)

        viewModel.checkEligibility(for: site.siteID) { [weak self] result in
            guard let self = self else { return }

            self.updateActionButtonAndTableState(animating: false, enabled: true)

            switch result {
            case .success:
                // if user is eligible, then switch to the desired store.
                delegate.didSelectStore(with: site.siteID) { [weak self] in
                    self?.dismiss()
                }
            case .failure(let error):
                if case let RoleEligibilityError.insufficientRole(errorInfo) = error {
                    ServiceLocator.analytics.track(event: .Login.insufficientRole(currentRoles: errorInfo.roles))
                    delegate.showRoleErrorScreen(for: site.siteID, errorInfo: errorInfo) { [weak self] in
                        self?.dismiss()
                    }
                } else {
                    self.displayUnknownErrorModal()
                }
            }
        }
    }
}

private extension StorePickerViewController {
    enum Localization {
        static let continueButton = NSLocalizedString("Continue", comment: "Button on the Store Picker screen to select a store")
        static let tryAnotherAccount = NSLocalizedString("Log In With Another Account",
                                                         comment: "Button to trigger connection to another account in store picker")
        static let createStore = NSLocalizedString("Create a new store",
                                                   comment: "Button to create a new store from the store picker")
        static let connectExistingStore = NSLocalizedString("Connect an existing store",
                                                            comment: "Button to connect to an existing store from the store picker")
        static let cancel = NSLocalizedString("Cancel",
                                              comment: "Button to dismiss the action sheet on the store picker")
        static let addStoreButton = NSLocalizedString("Add a Store",
                                                      comment: "Button title on the store picker for store creation")
        enum ActionMenu {
            static let logOut = NSLocalizedString("Log out",
                                                  comment: "Button to log out from the current account from the store picker")
            static let help = NSLocalizedString("Help",
                                                comment: "Button to get help from the store picker")
            static let closeAccount = NSLocalizedString(
                "Close account",
                comment: "Button to close the WordPress.com account on the store picker."
            )
        }
    }
}

// MARK: - StorePickerConstants: Contains all of the constants required by the Picker.
//
private enum StorePickerConstants {
    static let estimatedRowHeight = CGFloat(50)
}


// MARK: - Represents the StorePickerViewController's Internal State.
//
enum StorePickerState {

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
