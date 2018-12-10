import Foundation
import Yosemite



// MARK: - StoresManager
//
class StoresManager {

    /// Shared Instance
    ///
    static var shared = StoresManager(sessionManager: .standard)

    /// SessionManager: Persistent Storage for Session-Y Properties.
    ///
    private(set) var sessionManager: SessionManager

    /// Active StoresManager State.
    ///
    private var state: StoresManagerState {
        willSet {
            state.willLeave()
        }
        didSet {
            state.didEnter()
        }
    }

    /// Indicates if the StoresManager is currently authenticated, or not.
    ///
    var isAuthenticated: Bool {
        return state is AuthenticatedState
    }

    /// Indicates if we need a Default StoreID, or there's one already set.
    ///
    var needsDefaultStore: Bool {
        return sessionManager.defaultStoreID == nil
    }



    /// Designated Initializer
    ///
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
        self.state = AuthenticatedState(sessionManager: sessionManager) ?? DeauthenticatedState()

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
        synchronizeAccount { _ in
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

    /// Switches the state to a Deauthenticated one.
    ///
    @discardableResult
    func deauthenticate() -> StoresManager {
        state = DeauthenticatedState()

        sessionManager.reset()
        WooAnalytics.shared.refreshUserData()
        AppDelegate.shared.storageManager.reset()

        return self
    }

    /// Updates the Default Store as specified.
    ///
    func updateDefaultStore(storeID: Int) {
        sessionManager.defaultStoreID = storeID
        restoreSessionSiteIfPossible()

        NotificationCenter.default.post(name: .StoresManagerDidUpdateDefaultSite, object: nil)
    }
}


// MARK: - Private Methods
//
private extension StoresManager {

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
    func restoreSessionAccount(with accountID: Int) {
        let action = AccountAction.loadAccount(userID: accountID) { [weak self] account in
            guard let `self` = self, let account = account else {
                return
            }

            self.sessionManager.defaultAccount = account
        }

        dispatch(action)
    }

    /// Synchronizes the WordPress.com Account, associated with the current credentials.
    ///
    func synchronizeAccount(onCompletion: ((Error?) -> Void)?) {
        let action = AccountAction.synchronizeAccount { [weak self] (account, error) in
            if let `self` = self, let account = account, self.isAuthenticated {
                self.sessionManager.defaultAccount = account
                WooAnalytics.shared.refreshUserData()
            }

            onCompletion?(error)
        }

        dispatch(action)
    }

    /// Synchronizes the WordPress.com Sites, associated with the current credentials.
    ///
    func synchronizeSites(onCompletion: ((Error?) -> Void)?) {
        let action = AccountAction.synchronizeSites { error in
            onCompletion?(error)
        }

        dispatch(action)
    }

    /// Loads the specified site settings, if possible.
    ///
    func fetchSiteSettings(with siteID: Int) {
        guard siteID != 0 else {
            // Just return if the siteID == 0 so we are not making extra requests
            return
        }
        let action = SettingAction.retrieveSiteSettings(siteID: siteID) { error in
            if let error = error {
                DDLogError("⛔️ Could not successfully fetch settings for siteID \(siteID): \(error)")
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

        restoreSessionSite(with: siteID)
        fetchSiteSettings(with: siteID)
    }

    /// Loads the specified siteID into the Session, if possible.
    ///
    func restoreSessionSite(with siteID: Int) {
        let action = AccountAction.loadSite(siteID: siteID) { [weak self] site in
            guard let `self` = self, let site = site else {
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
