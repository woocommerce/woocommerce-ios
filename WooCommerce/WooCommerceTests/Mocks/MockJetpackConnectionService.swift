import Foundation
import Yosemite
@testable import WooCommerce

final class MockJetpackConnectionService: JetpackConnectionServiceProtocol {
    var evaluateAndConnectResult: Result<JetpackConnectionOutcome, Error> = .success(.connected(email: "test@example.com"))
    private(set) var evaluateAndConnectCallCount = 0

    var verifyConnectionResult: Result<String, Error> = .success("test@example.com")
    private(set) var verifyConnectionCallCount = 0

    var fetchJetpackConnectionURLResult: Result<URL, Error> = .success(URL(string: "https://jetpack.wordpress.com/jetpack.authorize")!)
    private(set) var fetchJetpackConnectionURLCallCount = 0
    private(set) var lastAuthenticatedWithWPCom: Bool?

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
}
