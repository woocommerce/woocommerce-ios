import Foundation

public class MockAccountRemote: AccountRemoteProtocol {

    private let objectGraph: MockObjectGraph

    public init(objectGraph: MockObjectGraph) {
        self.objectGraph = objectGraph
    }

    public func loadAccount(completion: @escaping (Account?, Error?) -> Void) {
        completion(objectGraph.defaultAccount, nil)
    }

    public func loadAccountSettings(for userID: Int64, completion: @escaping (AccountSettings?, Error?) -> Void) {
        completion(objectGraph.accountSettingsWithUserId(userId: userID), nil)
    }

    public func updateAccountSettings(for userID: Int64, tracksOptOut: Bool, completion: @escaping (AccountSettings?, Error?) -> Void) {
        completion(objectGraph.accountSettingsWithUserId(userId: userID), nil)
    }

    public func loadSites(completion: @escaping ([Site]?, Error?) -> Void) {
        completion(objectGraph.sites, nil)
    }

    public func loadSitePlan(for siteID: Int64, completion: @escaping (SitePlan?, Error?) -> Void) {
        completion(nil, nil)
    }
}
