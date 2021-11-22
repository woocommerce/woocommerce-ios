import Combine
import Foundation
import Yosemite
import Observables
import enum Networking.DotcomError
import class Networking.UserAgent

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
    init(sessionManager: SessionManagerProtocol) {
        _sessionManager = sessionManager
        self.state = AuthenticatedState(sessionManager: sessionManager) ?? DeauthenticatedState()

        isLoggedIn = isAuthenticated

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

        return self
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
        ServiceLocator.analytics.refreshUserData()
        ZendeskManager.shared.reset()
        ServiceLocator.pushNotesManager.unregisterForRemoteNotifications()
    }

    /// Switches the state to a Deauthenticated one.
    ///
    @discardableResult
    func deauthenticate() -> StoresManager {
        let resetAction = CardPresentPaymentAction.reset
        ServiceLocator.stores.dispatch(resetAction)

        state = DeauthenticatedState()

        sessionManager.reset()
        ServiceLocator.analytics.refreshUserData()
        ZendeskManager.shared.reset()
        ServiceLocator.storageManager.reset()

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
        restoreSessionSiteIfPossible()
        ServiceLocator.pushNotesManager.reloadBadgeCount()

        NotificationCenter.default.post(name: .StoresManagerDidUpdateDefaultSite, object: nil)
    }

    /// Updates the user roles for the default Store site.
    ///
    func updateDefaultRoles(_ roles: [User.Role]) {
        sessionManager.defaultRoles = roles
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
            credentials.hasPlaceholderUsername() else {
                return
        }
        authenticate(credentials: .init(username: account.username, authToken: credentials.authToken, siteAddress: credentials.siteAddress))
    }

    /// Synchronizes the WordPress.com Sites, associated with the current credentials.
    ///
    func synchronizeSites(onCompletion: @escaping (Result<Void, Error>) -> Void) {
        let action = AccountAction
            .synchronizeSites(selectedSiteID: sessionManager.defaultStoreID,
                              isJetpackConnectionPackageSupported: ServiceLocator.featureFlagService.isFeatureFlagEnabled(.jetpackConnectionPackageSupport),
                              onCompletion: onCompletion)
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

        group.enter()
        let sitePlanAction = AccountAction.synchronizeSitePlan(siteID: siteID) { result in
            if case let .failure(error) = result {
                errors.append(error)
            }
            group.leave()
        }
        dispatch(sitePlanAction)

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
    func retrieveOrderStatus(with siteID: Int64) {
        guard siteID != 0 else {
            // Just return if the siteID == 0 so we are not making extra requests
            return
        }

        let action = OrderStatusAction.retrieveOrderStatuses(siteID: siteID) { result in
            if case let .failure(error) = result {
                DDLogError("⛔️ Could not successfully fetch order statuses for siteID \(siteID): \(error)")
            }
        }

        dispatch(action)
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

    /// Synchronizes all system plugins for the store with specifie ID
    ///
    func synchronizeSystemPlugins(siteID: Int64) {
        let action = SystemStatusAction.synchronizeSystemPlugins(siteID: siteID) { result in
            if let error = result.failure {
                DDLogError("⛔️ Failed to sync system plugins for siteID: \(siteID). Error: \(error)")
            }
        }
        dispatch(action)
    }

    /// Sends telemetry data after availability check
    ///
    func sendTelemetryIfNeeded(siteID: Int64) {
        let checkAvailabilityAction = AppSettingsAction.getTelemetryInfo(siteID: siteID) { [weak self] isAvailable, telemetryLastReportedTime in
            guard let self = self else { return }

            if isAvailable {
                self.sendTelemetry(siteID: siteID, telemetryLastReportedTime: telemetryLastReportedTime)
            }
        }
        dispatch(checkAvailabilityAction)
    }

    /// Sends telemetry data
    ///
    func sendTelemetry(siteID: Int64, telemetryLastReportedTime: Date?) {
        let action = TelemetryAction.sendTelemetry(siteID: siteID,
                                                   versionString: UserAgent.bundleShortVersion,
                                                   telemetryLastReportedTime: telemetryLastReportedTime) { [weak self] result in
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

        restoreSessionSiteAndSynchronizeIfNeeded(with: siteID)
        synchronizeSettings(with: siteID) {
            ServiceLocator.selectedSiteSettings.refresh()
            ServiceLocator.shippingSettingsService.update(siteID: siteID)
        }
        retrieveOrderStatus(with: siteID)
        synchronizePaymentGateways(siteID: siteID)
        synchronizeAddOnsGroups(siteID: siteID)
        synchronizeSystemPlugins(siteID: siteID)

        sendTelemetryIfNeeded(siteID: siteID)
    }

    /// Loads the specified siteID into the Session, if possible.
    /// If the site does not exist in storage, it synchronizes the site asynchronously.
    ///
    func restoreSessionSiteAndSynchronizeIfNeeded(with siteID: Int64) {
        let isJCPEnabled = ServiceLocator.featureFlagService.isFeatureFlagEnabled(.jetpackConnectionPackageSupport)
        let action = AccountAction
            .loadAndSynchronizeSiteIfNeeded(siteID: siteID,
                                            isJetpackConnectionPackageSupported: isJCPEnabled) { [weak self] result in
            guard let self = self else { return }
            guard case .success(let site) = result else {
                return
            }
            self.sessionManager.defaultSite = site
        }
        dispatch(action)
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
