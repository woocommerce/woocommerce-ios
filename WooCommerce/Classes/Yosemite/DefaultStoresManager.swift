import Combine
import Foundation
import Yosemite
import enum Networking.DotcomError
import class Networking.UserAgent
import class Networking.WordPressOrgNetwork
import KeychainAccess
import class WidgetKit.WidgetCenter
import Experiments
import WordPressAuthenticator

// MARK: - DefaultStoresManager
//
class DefaultStoresManager: StoresManager {

    private let sessionManagerLockQueue = DispatchQueue(label: "StoresManager.sessionManagerLockQueue")

    /// SessionManager: Persistent Storage for Session-Y Properties.
    /// Private property. To be only accessed through `sessionManager` to make
    /// access thread safe.
    /// This seems to fix a crash:
    /// `Thread 1: Simultaneous accesses to <MEMORY_ADDESS>, but modification requires exclusive access`
    /// https://github.com/woocommerce/woocommerce-ios/issues/878
    private var _sessionManager: SessionManagerProtocol

    private let defaults: UserDefaults

    /// Keychain access. Used for sharing the auth access token with the widgets extension.
    ///
    private lazy var keychain = Keychain(service: WooConstants.keychainServiceName)

    /// Observes application password generation failure notification
    ///
    private var applicationPasswordGenerationFailureObserver: NSObjectProtocol?

    /// Observes invalid WPCOM token notification
    ///
    private var invalidWPCOMTokenNotificationObserver: NSObjectProtocol?

    /// NotificationCenter
    ///
    private let notificationCenter: NotificationCenter

    /// SessionManager: Persistent Storage for Session-Y Properties.
    /// This property is thread safe
    private(set) var sessionManager: SessionManagerProtocol {
        get {
            return sessionManagerLockQueue.sync {
                return _sessionManager
            }
        }

        set {
            sessionManagerLockQueue.sync {
                _sessionManager = newValue
            }
        }
    }

    /// Active StoresManager State.
    ///
    private var state: StoresManagerState {
        willSet {
            state.willLeave()
        }
        didSet {
            state.didEnter()
            isLoggedIn = isAuthenticated
        }
    }

    /// Indicates if the StoresManager is currently authenticated, or not.
    ///
    var isAuthenticated: Bool {
        return state is AuthenticatedState
    }

    /// Indicates if the StoresManager is currently authenticated with site credentials only.
    ///
    var isAuthenticatedWithoutWPCom: Bool {
        guard let credentials = sessionManager.defaultCredentials else {
            return false
        }
        if case .wpcom = credentials {
            return false
        }
        return true
    }

    @Published private var isLoggedIn: Bool = false

    var isLoggedInPublisher: AnyPublisher<Bool, Never> {
        $isLoggedIn
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    /// Indicates if we need a Default StoreID, or there's one already set.
    ///
    var needsDefaultStore: Bool {
        return sessionManager.defaultStoreID == nil
    }

    var needsDefaultStorePublisher: AnyPublisher<Bool, Never> {
        sessionManager.defaultStoreIDPublisher
            .map { $0 == nil }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var siteID: AnyPublisher<Int64?, Never> {
        sessionManager.defaultStoreIDPublisher
    }

    var site: AnyPublisher<Site?, Never> {
        sessionManager.defaultSitePublisher
    }

    /// Designated Initializer
    ///
    init(sessionManager: SessionManagerProtocol,
         notificationCenter: NotificationCenter = .default,
         defaults: UserDefaults = .standard) {
        _sessionManager = sessionManager
        self.state = AuthenticatedState(sessionManager: sessionManager) ?? DeauthenticatedState()
        self.notificationCenter = notificationCenter
        self.defaults = defaults

        isLoggedIn = isAuthenticated
    }

    /// This should only be invoked after all the ServiceLocator dependencies in this function are initialized to avoid circular reference.
    func initializeAfterDependenciesAreInitialized() {
        fullyDeauthenticateIfNeeded()
        restoreSessionAccountIfPossible()
        restoreSessionSiteIfPossible()
    }


    /// Forwards the Action to the current State.
    ///
    func dispatch(_ action: Action) {
        state.onAction(action)
    }

    /// Forwards the Actions to the current State.
    ///
    func dispatch(_ actions: [Action]) {
        for action in actions {
            state.onAction(action)
        }
    }

    /// Switches the internal state to Authenticated.
    ///
    @discardableResult
    func authenticate(credentials: Credentials) -> StoresManager {
        state = AuthenticatedState(credentials: credentials)
        sessionManager.defaultCredentials = credentials

        listenToApplicationPasswordGenerationFailureNotification()
        listenToWPCOMInvalidWPCOMTokenNotification()

        return self
    }

    /// De-authenticates upon receiving `ApplicationPasswordsGenerationFailed` notification
    ///
    func listenToApplicationPasswordGenerationFailureNotification() {
        applicationPasswordGenerationFailureObserver = notificationCenter.addObserver(forName: .ApplicationPasswordsGenerationFailed,
                                                                                      object: nil,
                                                                                      queue: .main) { [weak self] note in
            _ = self?.deauthenticate()
        }
    }

    /// De-authenticates upon receiving `RemoteDidReceiveInvalidTokenError` notification
    ///
    func listenToWPCOMInvalidWPCOMTokenNotification() {
        invalidWPCOMTokenNotificationObserver = notificationCenter.addObserver(forName: .RemoteDidReceiveInvalidTokenError,
                                                                               object: nil,
                                                                               queue: .main) { [weak self] note in
            _ = self?.deauthenticate()
        }
    }

    /// Synchronizes all of the Session's Entities.
    ///
    @discardableResult
    func synchronizeEntities(onCompletion: (() -> Void)? = nil) -> StoresManager {
        let group = DispatchGroup()

        group.enter()
        synchronizeAccount { [weak self] _ in
            group.enter()
            self?.synchronizeAccountSettings { _ in
                group.leave()
            }
            group.leave()
        }

        group.enter()
        synchronizeSites { _ in
            group.leave()
        }

        group.notify(queue: .main) {
            onCompletion?()
        }

        return self
    }

    /// Prepares for changing the selected store and remains Authenticated.
    ///
    func removeDefaultStore() {
        sessionManager.deleteApplicationPassword()
        ServiceLocator.analytics.refreshUserData()
        ZendeskProvider.shared.reset()
        ServiceLocator.pushNotesManager.unregisterForRemoteNotifications()
    }

    /// Fully deauthenticates the user, if needed.
    ///
    /// This handles the scenario where `DefaultStoresManager` can't be initialized
    /// in an authenticated state, but the default store is unexpectedly still set.
    ///
    private func fullyDeauthenticateIfNeeded() {
        guard !isLoggedIn && !needsDefaultStore else {
            return
        }

        deauthenticate()
    }

    /// Switches the state to a Deauthenticated one.
    ///
    @discardableResult
    func deauthenticate() -> StoresManager {
        applicationPasswordGenerationFailureObserver = nil

        let resetAction = CardPresentPaymentAction.reset
        dispatch(resetAction)

        state = DeauthenticatedState()

        sessionManager.reset()
        ServiceLocator.analytics.refreshUserData()
        ZendeskProvider.shared.reset()
        ServiceLocator.storageManager.reset()
        ServiceLocator.productImageUploader.reset()

        updateAndReloadWidgetInformation(with: nil)

        NotificationCenter.default.post(name: .logOutEventReceived, object: nil)

        return self
    }

    /// Updates the Default Store as specified.
    /// After this call, `siteID` is updated while `site` might still be nil when it is a newly connected site.
    /// In the case of a newly connected site, it synchronizes the site asynchronously and `site` observable is updated.
    ///
    func updateDefaultStore(storeID: Int64) {
        sessionManager.defaultStoreID = storeID
        // Because `defaultSite` is loaded or synced asynchronously, it is reset here so that any UI that calls this does not show outdated data.
        // For example, `sessionManager.defaultSite` is used to show site name in various screens in the app.
        sessionManager.defaultSite = nil
        defaults[.storePhoneNumber] = nil
        defaults[.completedAllStoreOnboardingTasks] = nil
        defaults[.usedProductDescriptionAI] = nil
        defaults[.hasDismissedWriteWithAITooltip] = nil
        defaults[.numberOfTimesWriteWithAITooltipIsShown] = nil
        defaults[.latestBackgroundOrderSyncDate] = nil
        DashboardTimestampStore.resetStore()
        restoreSessionSiteIfPossible()
        ServiceLocator.pushNotesManager.reloadBadgeCount()

        NotificationCenter.default.post(name: .StoresManagerDidUpdateDefaultSite, object: nil)
    }

    /// Updates the default site only in cases where a site's properties are updated (e.g. after installing & activating Jetpack-the-plugin).
    ///
    func updateDefaultStore(_ site: Site) {
        guard site.siteID == sessionManager.defaultStoreID else {
            return
        }
        sessionManager.defaultSite = site
    }

    /// Updates the user roles for the default Store site.
    ///
    func updateDefaultRoles(_ roles: [User.Role]) {
        sessionManager.defaultRoles = roles
    }

    func shouldAuthenticateAdminPage(for site: Site) -> Bool {
        /// If the site is self-hosted and user is authenticated with WPCom,
        /// `AuthenticatedWebView` will attempt to authenticate and redirect to the admin page and fails.
        /// This should be prevented 💀⛔️
        guard site.isWordPressComStore || isAuthenticatedWithoutWPCom else {
            return false
        }
        return true
    }
}


// MARK: - Private Methods
//
private extension DefaultStoresManager {

    /// Loads the Default Account into the current Session, if possible.
    ///
    func restoreSessionAccountIfPossible() {
        guard let accountID = sessionManager.defaultAccountID else {
            return
        }

        restoreSessionAccount(with: accountID)
    }

    /// Loads the specified accountID into the Session, if possible.
    ///
    func restoreSessionAccount(with accountID: Int64) {
        let action = AccountAction.loadAccount(userID: accountID) { [weak self] account in
            guard let `self` = self, let account = account else {
                return
            }
            self.replaceTempCredentialsIfNecessary(account: account)
            self.sessionManager.defaultAccount = account
        }

        dispatch(action)
    }

    /// Synchronizes the WordPress.com Account, associated with the current credentials.
    ///
    func synchronizeAccount(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let action = AccountAction.synchronizeAccount { [weak self] result in
            switch result {
            case .success(let account):
                if let self = self, self.isAuthenticated {
                    self.sessionManager.defaultAccount = account
                    ServiceLocator.analytics.refreshUserData()
                }
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }

        dispatch(action)
    }

    /// Synchronizes the WordPress.com Account Settings, associated with the current credentials.
    ///
    func synchronizeAccountSettings(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = sessionManager.defaultAccount?.userID else {
            onCompletion(.failure(StoresManagerError.missingDefaultSite))
            return
        }

        let action = AccountAction.synchronizeAccountSettings(userID: userID) { [weak self] result in
            switch result {
            case .success(let accountSettings):
                if let self = self, self.isAuthenticated {
                    // Save the user's preference
                    ServiceLocator.analytics.setUserHasOptedOut(accountSettings.tracksOptOut)
                }
                onCompletion(.success(()))
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }

        dispatch(action)
    }

    /// Replaces the temporary UUID username in default credentials with the
    /// actual username from the passed account.  This *shouldn't* be necessary
    /// under normal conditions but is a safety net in case there is an error
    /// preventing the temp username from being updated during login.
    ///
    func replaceTempCredentialsIfNecessary(account: Account) {
        guard
            let credentials = sessionManager.defaultCredentials,
            case let .wpcom(_, authToken, siteAddress) = credentials, // Only WPCOM creds have placeholder `username`. WPOrg creds have user entered `username`
            credentials.hasPlaceholderUsername() else {
            return
        }
        authenticate(credentials: .wpcom(username: account.username, authToken: authToken, siteAddress: siteAddress))
    }

    /// Synchronizes the WordPress.com Sites, associated with the current credentials.
    ///
    func synchronizeSites(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let action = AccountAction
            .synchronizeSites(selectedSiteID: sessionManager.defaultStoreID) { result in
                onCompletion(result.map { _ in () })
            }
        dispatch(action)
    }

    /// Synchronizes the settings for the specified site, if possible.
    ///
    func synchronizeSettings(with siteID: Int64, onCompletion: @escaping () -> Void) {
        guard siteID != 0 else {
            // Just return if the siteID == 0 so we are not making extra requests
            return
        }

        let group = DispatchGroup()
        var errors = [Error]()

        group.enter()
        let generalSettingsAction = SettingAction.synchronizeGeneralSiteSettings(siteID: siteID) { error in
            if let error = error {
                errors.append(error)
            }
            group.leave()
        }
        dispatch(generalSettingsAction)

        group.enter()
        let productSettingsAction = SettingAction.synchronizeProductSiteSettings(siteID: siteID) { error in
            if let error = error {
                errors.append(error)
            }
            group.leave()
        }
        dispatch(productSettingsAction)

        /// skips synchronizing site plan if logged in with WPOrg credentials
        /// because this requires a WPCom endpoint.
        if isAuthenticatedWithoutWPCom == false {
            group.enter()
            let sitePlanAction = AccountAction.synchronizeSitePlan(siteID: siteID) { result in
                if case let .failure(error) = result {
                    errors.append(error)
                }
                group.leave()
            }
            dispatch(sitePlanAction)
        }

        group.notify(queue: .main) {
            if errors.isEmpty {
                DDLogInfo("🎛 Site settings sync completed for siteID \(siteID)")
            } else {
                DDLogError("⛔️ Site settings sync had \(errors.count) error(s) for siteID \(siteID): \(errors)")
            }
            onCompletion()
        }
    }

    /// Synchronizes all payment gateways.
    ///
    func synchronizePaymentGateways(siteID: Int64) {
        let action = PaymentGatewayAction.synchronizePaymentGateways(siteID: siteID) { result in
            if let error = result.failure {
                DDLogError("⛔️ Failed to sync payment gateways for siteID: \(siteID). Error: \(error)")
            }
        }
        dispatch(action)
    }

    /// Synchronizes the order statuses, if possible.
    ///
    @MainActor
    func retrieveOrderStatus(with siteID: Int64) async -> [OrderStatus]? {
        guard siteID != 0 else {
            // Just return if the siteID == 0 so we are not making extra requests
            return nil
        }

        return await withCheckedContinuation { continuation in
            dispatch(OrderStatusAction.retrieveOrderStatuses(siteID: siteID) { result in
                switch result {
                    case let .success(statuses):
                        continuation.resume(returning: statuses)
                    case let .failure(error):
                        DDLogError("⛔️ Could not successfully fetch order statuses for siteID \(siteID): \(error)")
                        continuation.resume(returning: nil)
                }
            })
        }
    }

    /// Synchronizes the number of products for site snapshot tracking.
    ///
    @MainActor
    func retrieveNumberOfProducts(siteID: Int64) async -> Int64? {
        guard siteID != 0 else {
            // Just return if the siteID == 0 so we are not making extra requests
            return nil
        }

        return await withCheckedContinuation { continuation in
            dispatch(ProductAction.fetchNumberOfProducts(siteID: siteID) { result in
                switch result {
                    case let .success(numberOfProducts):
                        continuation.resume(returning: numberOfProducts)
                    case let .failure(error):
                        DDLogError("⛔️ Could not successfully fetch number of products for siteID \(siteID): \(error)")
                        continuation.resume(returning: nil)
                }
            })
        }
    }

    /// Synchronizes all add-ons groups(global add-ons).
    ///
    func synchronizeAddOnsGroups(siteID: Int64) {
        let action = AddOnGroupAction.synchronizeAddOnGroups(siteID: siteID) { result in
            if let error = result.failure {
                if error as? DotcomError == .noRestRoute {
                    DDLogError("⚠️ Endpoint for add-on groups is unreachable for siteID: \(siteID). WC Product Add-Ons plugin may be missing.")
                } else {
                    DDLogError("⛔️ Failed to sync add-on groups for siteID: \(siteID). Error: \(error)")
                }
            }
        }
        dispatch(action)
    }

    /// Synchronizes all system information for the store with specified ID.
    /// When finished, loads the store uuid into the session.
    ///
    @MainActor
    func synchronizeSystemInformation(siteID: Int64) async -> SystemInformation? {
        await withCheckedContinuation { continuation in
            dispatch(SystemStatusAction.synchronizeSystemInformation(siteID: siteID) { [weak self] result in
                switch result {
                case let .success(systemInformation):
                    DDLogInfo("🟢 Successfully synced system information")
                    self?.loadStoreUUID(siteID: siteID)
                    continuation.resume(returning: systemInformation)
                case let .failure(error):
                    DDLogError("⛔️ Failed to sync system plugins for siteID: \(siteID). Error: \(error)")
                    continuation.resume(returning: nil)
                }
            })
        }
    }

    /// Synchronizes all site plugins for the store with specified ID
    ///
    func synchronizeSitePlugins(siteID: Int64) {
        // Check if the user is an admin, otherwise they can't fetch plugins.
        guard sessionManager.defaultRoles.contains(.administrator) == true else {
            DDLogError("⛔️ Failed to sync site plugins for siteID: \(siteID). The user is not an admin.")
            return
        }
        let action = SitePluginAction.synchronizeSitePlugins(siteID: siteID) { result in
            if let error = result.failure {
                DDLogError("⛔️ Failed to sync site plugins for siteID: \(siteID). Error: \(error)")
            }
        }
        dispatch(action)
    }

    /// Loads the stored `storeUUID` from the `AppSettings` store.
    ///
    func loadStoreUUID(siteID: Int64) {
        let action = AppSettingsAction.getStoreID(siteID: siteID) { [weak self] storeUUID in
            self?.sessionManager.defaultStoreUUID = storeUUID
            DDLogInfo("🟢 Loaded Store UUID: " + (String(describing: storeUUID)))
        }
        dispatch(action)
    }

    /// Sends telemetry data after availability check
    ///
    func sendTelemetryIfNeeded(siteID: Int64) {
        let checkAvailabilityAction = AppSettingsAction.getTelemetryInfo(siteID: siteID) { [weak self] isAvailable, telemetryLastReportedTime in
            guard let self = self else { return }

            if isAvailable {
                self.sendTelemetry(siteID: siteID,
                                   telemetryLastReportedTime: telemetryLastReportedTime,
                                   installationDate: self.defaults.object(forKey: .installationDate))
            }
        }
        dispatch(checkAvailabilityAction)
    }

    /// Sends telemetry data
    ///
    func sendTelemetry(siteID: Int64, telemetryLastReportedTime: Date?, installationDate: Date?) {
        let action = TelemetryAction.sendTelemetry(siteID: siteID,
                                                   versionString: UserAgent.bundleShortVersion,
                                                   telemetryLastReportedTime: telemetryLastReportedTime,
                                                   installationDate: installationDate) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                let saveTimestampAction = AppSettingsAction.setTelemetryLastReportedTime(siteID: siteID, time: Date())
                self.dispatch(saveTimestampAction)
                DDLogInfo("Successfully sent telemetry for siteID: \(siteID).")
            case .failure(let error):
                if error as? TelemetryError != .requestThrottled {
                    DDLogError("⛔️ Failed to send telemetry for siteID: \(siteID). Error: \(error)")
                }
            }
        }
        dispatch(action)
    }

    /// Loads the Default Site into the current Session, if possible.
    ///
    func restoreSessionSiteIfPossible() {
        guard let siteID = sessionManager.defaultStoreID else {
            return
        }

        if siteID == WooConstants.placeholderStoreID,
           let url = sessionManager.defaultCredentials?.siteAddress {
            restoreSessionSite(with: url)
        } else {
            restoreSessionSiteAndSynchronizeIfNeeded(with: siteID)
        }

        synchronizeSettings(with: siteID) {
            ServiceLocator.selectedSiteSettings.refresh()
            ServiceLocator.shippingSettingsService.update(siteID: siteID)
        }
        synchronizePaymentGateways(siteID: siteID)
        synchronizeAddOnsGroups(siteID: siteID)
        synchronizeSitePlugins(siteID: siteID)
        loadStoreUUID(siteID: siteID)

        sendTelemetryIfNeeded(siteID: siteID)

        Task { @MainActor in
            // Order statuses and system plugins syncing are required outside of snapshot tracking.
            async let orderStatuses = retrieveOrderStatus(with: siteID)
            async let systemInformation = synchronizeSystemInformation(siteID: siteID)

            trackSnapshotIfNeeded(siteID: siteID, orderStatuses: await orderStatuses, systemPlugins: await systemInformation?.systemPlugins)
        }
    }

    /// Load the site with the specified URL into the session if possible.
    ///
    func restoreSessionSite(with url: String) {
        let action = WordPressSiteAction.fetchSiteInfo(siteURL: url) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let site):
                self.sessionManager.defaultSite = site
                self.updateAndReloadWidgetInformation(with: site.siteID)
                /// Trigger the `v1.1/connect/site-info` API to get information about
                /// the site's Jetpack status and whether it's a WPCom site.
                WordPressAuthenticator.fetchSiteInfo(for: url) { [weak self] result in
                    guard let self else { return }
                    switch result {
                    case .success(let info):
                        let updatedSite = site.copy(isJetpackThePluginInstalled: info.hasJetpack,
                                                    isJetpackConnected: info.isJetpackConnected,
                                                    isWordPressComStore: info.isWPCom)
                        self.sessionManager.defaultSite = updatedSite
                        self.updateAndReloadWidgetInformation(with: site.siteID)
                    case .failure(let error):
                        DDLogError("⛔️ Cannot fetch generic site info: \(error)")
                    }
                }
            case .failure(let error):
                DDLogError("⛔️ Cannot fetch WordPress site info: \(error)")
            }
        }
        dispatch(action)
    }

    /// Loads the specified siteID into the Session, if possible.
    /// If the site does not exist in storage, it synchronizes the site asynchronously.
    ///
    func restoreSessionSiteAndSynchronizeIfNeeded(with siteID: Int64) {
        let action = AccountAction
            .loadAndSynchronizeSite(siteID: siteID,
                                    forcedUpdate: false) { [weak self] result in
            guard let self = self else { return }
            guard case .success(let site) = result else {
                return
            }
            self.sessionManager.defaultSite = site
            self.updateAndReloadWidgetInformation(with: siteID)
        }
        dispatch(action)
    }

    /// Updates the necessary dependencies for the widget to function correctly.
    /// Reloads widgets timelines.
    ///
    func updateAndReloadWidgetInformation(with siteID: Int64?) {
        // Token/password to fire network requests
        keychain.currentAuthToken = nil
        keychain.siteCredentialPassword = nil
        switch sessionManager.defaultCredentials {
        case let .wpcom(_, authToken, _):
            keychain.currentAuthToken = authToken
        case let .wporg(username, password, siteAddress):
            keychain.siteCredentialPassword = password
            UserDefaults.group?[.defaultUsername] = username
            UserDefaults.group?[.defaultSiteAddress] = siteAddress
        case let .applicationPassword(username, _, siteAddress):
            UserDefaults.group?[.defaultUsername] = username
            UserDefaults.group?[.defaultSiteAddress] = siteAddress
        default:
            break
        }

        // Non-critical store info
        UserDefaults.group?[.defaultStoreID] = siteID
        UserDefaults.group?[.defaultStoreName] = sessionManager.defaultSite?.name

        // Currency Settings are stored in `SelectedSiteSettings.defaultStoreCurrencySettings`

        // Reload widgets UI
        WidgetCenter.shared.reloadAllTimelines()
    }

    func trackSnapshotIfNeeded(siteID: Int64, orderStatuses: [OrderStatus]?, systemPlugins: [SystemPlugin]?) {
        Task { @MainActor in
            let snapshotTracker = SiteSnapshotTracker(siteID: siteID)
            guard let orderStatuses, let systemPlugins else {
                return
            }
            guard snapshotTracker.needsTracking() else {
                return
            }
            // Only fetches number of products when snapshot tracking is needed.
            guard let numberOfProducts = await retrieveNumberOfProducts(siteID: siteID) else {
                return
            }
            snapshotTracker.trackIfNeeded(orderStatuses: orderStatuses,
                                          numberOfProducts: numberOfProducts,
                                          systemPlugins: systemPlugins)
        }
    }
}


// MARK: - StoresManagerState
//
protocol StoresManagerState {

    /// Executed before the state is deactivated.
    ///
    func willLeave()

    /// Executed whenever the State is activated.
    ///
    func didEnter()

    /// Executed whenever an Action is received.
    ///
    func onAction(_ action: Action)
}


// MARK: - StoresManagerError
//
enum StoresManagerError: Error {
    case missingDefaultSite
}
