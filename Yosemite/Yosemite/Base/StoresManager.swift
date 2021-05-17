import Combine
import Foundation
import Observables

/// Abstracts the Stores coordination
///
public protocol StoresManager {

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

    /// Publishes signal that indicates if the user is currently logged in with credentials.
    ///
    var isLoggedInPublisher: AnyPublisher<Bool, Never> { get }

    /// The currently logged in store/site ID. Nil when the app is logged out.
    ///
    var siteID: Observable<Int64?> { get }

    /// Indicates if we need a Default StoreID, or there's one already set.
    ///
    var needsDefaultStore: Bool { get }

    /// Publishes signal that indicates if we need a default store ID, or there is one already set.
    ///
    var needsDefaultStorePublisher: AnyPublisher<Bool, Never> { get }

    /// SessionManagerProtocol: Persistent Storage for Session-Y Properties.
    /// This property is thread safe
    var sessionManager: SessionManagerProtocol { get }
}
