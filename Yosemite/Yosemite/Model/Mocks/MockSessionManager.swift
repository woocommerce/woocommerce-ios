import Combine
import Foundation
import Observables

public struct MockSessionManager: SessionManagerProtocol {

    private let objectGraph: MockObjectGraph

    init(objectGraph: MockObjectGraph) {
        self.objectGraph = objectGraph
        self.storeIDSubject = BehaviorSubject<Int64?>(objectGraph.defaultSite.siteID)
        defaultAccount = objectGraph.defaultAccount
        defaultSite = objectGraph.defaultSite
        defaultStoreID = objectGraph.defaultSite.siteID
        defaultStoreIDPublisher = Just(objectGraph.defaultSite.siteID).eraseToAnyPublisher()
        defaultCredentials = objectGraph.userCredentials
    }

    public var defaultAccount: Account?

    public var defaultAccountID: Int64?

    public var defaultSite: Site?

    public var defaultStoreID: Int64?

    public var defaultStoreIDPublisher: AnyPublisher<Int64?, Never>

    public var defaultCredentials: Credentials?

    public var anonymousUserID: String? = nil

    /// Observable site ID
    ///
    public var siteID: Observable<Int64?> {
        storeIDSubject
    }

    private let storeIDSubject: BehaviorSubject<Int64?>

    public func reset() {
        // Do nothing
    }
}
