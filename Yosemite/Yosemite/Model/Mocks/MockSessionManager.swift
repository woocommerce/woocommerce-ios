import Combine
import Foundation

public struct MockSessionManager: SessionManagerProtocol {

    private let objectGraph: MockObjectGraph

    init(objectGraph: MockObjectGraph) {
        self.objectGraph = objectGraph
        defaultAccount = objectGraph.defaultAccount
        defaultSite = objectGraph.defaultSite
        defaultStoreID = objectGraph.defaultSite.siteID
        defaultStoreIDPublisher = Just(objectGraph.defaultSite.siteID).eraseToAnyPublisher()
        defaultCredentials = objectGraph.userCredentials
    }

    public var defaultAccount: Account?

    public var defaultAccountID: Int64?

    public var defaultSite: Site?

    public var defaultSitePublisher: AnyPublisher<Site?, Never> {
        Just(defaultSite).eraseToAnyPublisher()
    }

    public var defaultStoreID: Int64?

    public var defaultRoles: [User.Role] = []

    public var defaultStoreIDPublisher: AnyPublisher<Int64?, Never>

    public var defaultCredentials: Credentials?

    public var anonymousUserID: String? = nil

    public func reset() {
        // Do nothing
    }
}
