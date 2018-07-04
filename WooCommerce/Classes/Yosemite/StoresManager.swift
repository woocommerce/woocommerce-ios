import Foundation
import Yosemite
import Storage



// MARK: - StoresManager
//
class StoresManager {

    /// Shared Instance
    ///
    static var shared = StoresManager(keychainServiceName: Settings.keychainServiceName, defaultsStorage: .standard)

    /// Represents the Active Session's State
    ///
    private let session: Session

    /// Active StoresManager State.
    ///
    private var state: StoresManagerState = DeauthenticatedState() {
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
    init(keychainServiceName: String, defaultsStorage: UserDefaults) {
        self.session = Session(keychainServiceName: keychainServiceName, defaultsStorage: defaultsStorage)

        authenticateIfPossible()
    }


    /// Forwards the Action to the current State.
    ///
    func dispatch(_ action: Action) {
        state.onAction(action)
    }


    /// Switches the internal state to Authenticated.
    ///
    func authenticate(username: String, authToken: String) {
        let credentials = Credentials(username: username, authToken: authToken)

        state = AuthenticatedState(credentials: credentials)
        session.credentials = credentials
    }


    /// Switches the state to a Deauthenticated one.
    ///
    func deauthenticate() {
        state = DeauthenticatedState()
        session.credentials = nil
    }
}


// MARK: - StoresManager Private Methods
//
private extension StoresManager {

    /// Switches over to the AuthenticatedState whenever needed / possible!.
    ///
    func authenticateIfPossible() {
        guard !isAuthenticated, let credentials = session.credentials else {
            return
        }

        state = AuthenticatedState(credentials: credentials)
    }
}


// MARK: - Nested Types
//
private extension StoresManager {

    /// Default Settings.
    ///
    enum Settings  {
        static let keychainServiceName = "com.automattic.woocommerce"
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
