import Foundation
import Yosemite
@testable import WooCommerce

final class MockJetpackConnectionService: JetpackConnectionServiceProtocol {
    var connectResult: Result<String, Error> = .success("test@mail.com")
    private(set) var connectCallCount = 0
    private(set) var lastConnectionData: JetpackConnectionData?

    var verifyResult: Result<String, Error> = .success("test@mail.com")
    private(set) var verifyCallCount = 0

    func connect(with connectionData: JetpackConnectionData,
                 siteURL: String,
                 credentials: Credentials) async throws -> String {
        connectCallCount += 1
        lastConnectionData = connectionData
        return try connectResult.get()
    }

    func verifyConnection() async throws -> String {
        verifyCallCount += 1
        return try verifyResult.get()
    }
}
