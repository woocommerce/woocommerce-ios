import Foundation
import Yosemite
import Storage
import Networking



// MARK: - StoresManager
//
class StoresManager {

    ///
    ///
    private static var state: StoresManagerState = initialState() {
        didSet {
            state.didEnter()
        }
    }


    /// This class is meant to be non (publicly) instantiable!
    ///
    private init() { }


    ///
    ///
    class func authenticate(username: String, authToken: String) {
        let credentials = Credentials(username: username, authToken: authToken)
        state = state.authenticate(with: credentials)
    }


    ///
    ///
    class func deauthenticate() {
        state = state.deauthenticate()
    }


    ///
    ///
    class func dispatch(_ action: Action) {
        state.onAction(action)
    }
}


// MARK: - StoresManager Private Methods
//
private extension StoresManager {

    ///
    ///
    class func initialState() -> StoresManagerState {
        guard let credentials = CredentialsManager.shared.loadDefaultCredentials() else {
            return DeauthenticatedState()
        }

        return AuthenticatedState(credentials: credentials)
    }
}


// MARK: - StoresManagerState
//
private protocol StoresManagerState {

    ///
    ///
    func didEnter()

    ///
    ///
    func onAction(_ action: Action)

    ///
    ///
    func deauthenticate() -> StoresManagerState

    ///
    ///
    func authenticate(with credentials: Credentials) -> StoresManagerState
}


// MARK: - DeauthenticatedState
//
private class DeauthenticatedState: StoresManagerState {

    ///
    ///
    func didEnter() {
        CredentialsManager.shared.removeDefaultCredentials()
        AppDelegate.shared.displayAuthenticator()
    }

    ///
    ///
    func onAction(_ action: Action) { }


    ///
    ///
    func deauthenticate() -> StoresManagerState {
        return self
    }


    ///
    ///
    func authenticate(with credentials: Credentials) -> StoresManagerState {
        return AuthenticatedState(credentials: credentials)
    }
}


// MARK: - AuthenticatedState
//
private class AuthenticatedState: StoresManagerState {

    ///
    ///
    private let credentials: Credentials

    ///
    ///
    private let dispatcher = Dispatcher.global

    ///
    ///
    private let services: [ActionsProcessor]


    ///
    ///
    init(credentials: Credentials) {
        let storageManager = CoreDataManager.global
        let network = AlamofireNetwork(credentials: credentials)

        services = [
            AccountStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        ]

        self.credentials = credentials
    }


    ///
    ///
    func didEnter() {
        CredentialsManager.shared.saveDefaultCredentials(credentials)
    }


    ///
    ///
    func onAction(_ action: Action) {
        dispatcher.dispatch(action)
    }


    ///
    ///
    func deauthenticate() -> StoresManagerState {
        return DeauthenticatedState()
    }


    ///
    ///
    func authenticate(with credentials: Credentials) -> StoresManagerState {
        return AuthenticatedState(credentials: credentials)
    }
}
