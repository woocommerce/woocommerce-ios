import Foundation
@testable import WooCommerce

final class MockConnectionService: WPComConnectionServiceProtocol {
    var shouldSucceed: Bool
    var delay: TimeInterval

    init(shouldSucceed: Bool = true, delay: TimeInterval = 0) {
        self.shouldSucceed = shouldSucceed
        self.delay = delay
    }

    func connect() async throws {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if !shouldSucceed {
            throw MockError.anyError
        }
    }
}
