import Combine
import Foundation
import Observables

public protocol SessionManagerProtocol {

    /// Ephemeral: Default Account.
    ///
    var defaultAccount: Account? { get set}

    /// Default AccountID: Returns the last known Account's User ID.
    ///
    var defaultAccountID: Int64? { get }

    /// Default Store Site
    ///
    var defaultSite: Site? { get set }

    /// Default StoreID.
    ///
    var defaultStoreID: Int64? { get set }

    /// Publishes default store ID on change.
    ///
    var defaultStoreIDPublisher: AnyPublisher<Int64?, Never> { get }

    /// Anonymous UserID.
    ///
    var anonymousUserID: String? { get }

    /// Observable site ID
    ///
    var siteID: Observable<Int64?> { get }

    /// Default Credentials.
    ///
    var defaultCredentials: Credentials? { get set}

    /// Nukes all of the known Session's properties.
    ///
    func reset()
}
