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
        didSet {
            state.didEnter()
        }
    }

    /// Indicates if the StoresManager is currently authenticated, or not.
    ///
    var isAuthenticated: Bool {
        return state is AuthenticatedState
    }



    /// Designated Initializer
    ///
    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
        self.state = AuthenticatedState(sessionManager: sessionManager) ?? DeauthenticatedState()

        restoreSessionAccountIfPossible()
    }


    /// Forwards the Action to the current State.
    ///
    func dispatch(_ action: Action) {
        state.onAction(action)
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

        return self
    }

    /// Updates the Default Store as specified.
    ///
    func updateDefaultStore(storeID: Int) {
        sessionManager.defaultStoreID = storeID
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
}


// MARK: - StoresManagerState
//
protocol StoresManagerState {

    /// Executed whenever the State is activated.
    ///
    func didEnter()

    /// Executed whenever an Action is received.
    ///
    func onAction(_ action: Action)
}
