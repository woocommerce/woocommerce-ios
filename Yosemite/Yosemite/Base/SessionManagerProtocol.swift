import Foundation
import Observables

public protocol SessionManagerProtocol {
    var defaultAccount: Account? { get set}
    var defaultAccountID: Int64? { get }

    var defaultSite: Site? { get set }
    var defaultStoreID: Int64? { get set }

    var anonymousUserID: String? { get }

    var siteID: Observable<Int64?> { get }

    var defaultCredentials: Credentials? { get set}

    func reset()
}
