import Foundation
@testable import WooCommerce

final class MockPluginVersionChecker: PluginVersionCheckerProtocol {
    var result: PluginVersionResult
    var shouldThrow = false
    var delay: TimeInterval = 0

    init(result: PluginVersionResult = .compatible) {
        self.result = result
    }

    func checkCompatibility() async throws -> PluginVersionResult {
        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        if shouldThrow {
            throw MockError.anyError
        }
        return result
    }
}
