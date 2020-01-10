import Foundation
import Yosemite

/// Abstracts the Stores coordination
///
protocol StoresManager {

    /// Forwards the Action to the current State.
    ///
    func dispatch(_ action: Action)

    /// Forwards the Actions to the current State.
    ///
    func dispatch(_ actions: [Action])

    /// Prepares for changing the selected store and remains Authenticated.
    ///
    func removeDefaultStore()

    /// Switches the internal state to Authenticated.
    ///
    @discardableResult
    func authenticate(credentials: Credentials) -> StoresManager

    /// Switches the state to a Deauthenticated one.
    ///
    @discardableResult
    func deauthenticate() -> StoresManager

    /// Synchronizes all of the Session's Entities.
    ///
    @discardableResult
    func synchronizeEntities(onCompletion: (() -> Void)?) -> StoresManager

    /// Updates the Default Store as specified.
    ///
    func updateDefaultStore(storeID: Int64)

    /// Indicates if the StoresManager is currently authenticated, or not.
    ///
    var isAuthenticated: Bool { get }

    /// Indicates if we need a Default StoreID, or there's one already set.
    ///
    var needsDefaultStore: Bool { get }

    /// SessionManager: Persistent Storage for Session-Y Properties.
    /// This property is thread safe
    var sessionManager: SessionManager { get }
}
