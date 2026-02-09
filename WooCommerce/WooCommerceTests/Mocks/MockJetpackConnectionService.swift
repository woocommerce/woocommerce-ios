import Foundation
import Yosemite
@testable import WooCommerce

final class MockJetpackConnectionService: JetpackConnectionServiceProtocol {
    var connectResult: Result<Void, Error> = .success(())
    private(set) var connectCallCount = 0
    private(set) var lastConnectionData: JetpackConnectionData?

    func connect(with connectionData: JetpackConnectionData,
                 siteURL: String,
                 credentials: Credentials) async throws {
        connectCallCount += 1
        lastConnectionData = connectionData
        try connectResult.get()
    }
}
