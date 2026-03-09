import Foundation
import Yosemite
@testable import WooCommerce

final class MockJetpackConnectionService: JetpackConnectionServiceProtocol {
    var establishSiteConnectionResult: Result<Void, Error> = .success(())
    private(set) var establishSiteConnectionCallCount = 0

    var evaluateAndConnectResult: Result<JetpackConnectionOutcome, Error> = .success(.connected(email: "test@example.com"))
    private(set) var evaluateAndConnectCallCount = 0

    var verifyConnectionResult: Result<String, Error> = .success("test@example.com")
    private(set) var verifyConnectionCallCount = 0

    var fetchJetpackConnectionURLResult: Result<URL, Error> = .success(URL(string: "https://jetpack.wordpress.com/jetpack.authorize")!)
    private(set) var fetchJetpackConnectionURLCallCount = 0
    private(set) var lastAuthenticatedWithWPCom: Bool?

    var fetchConnectionDataResult: Result<JetpackConnectionData, Error>?
    private(set) var fetchConnectionDataCallCount = 0

    func establishSiteConnection(siteURL: String) async throws {
        establishSiteConnectionCallCount += 1
        try establishSiteConnectionResult.get()
    }

    func evaluateAndConnect(siteURL: String, credentials: Credentials) async throws -> JetpackConnectionOutcome {
        evaluateAndConnectCallCount += 1
        return try evaluateAndConnectResult.get()
    }

    func verifyConnection() async throws -> String {
        verifyConnectionCallCount += 1
        return try verifyConnectionResult.get()
    }

    func fetchJetpackConnectionURL(authenticatedWithWPCom: Bool) async throws -> URL {
        fetchJetpackConnectionURLCallCount += 1
        lastAuthenticatedWithWPCom = authenticatedWithWPCom
        return try fetchJetpackConnectionURLResult.get()
    }

    func fetchConnectionData() async throws -> JetpackConnectionData {
        fetchConnectionDataCallCount += 1
        guard let result = fetchConnectionDataResult else {
            throw NSError(domain: "MockJetpackConnectionService", code: 0, userInfo: [NSLocalizedDescriptionKey: "fetchConnectionDataResult not set"])
        }
        return try result.get()
    }
}
