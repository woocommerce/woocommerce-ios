@testable import WooCommerce

final class MockPluginChecker: PluginVersionCheckerProtocol {
    var result: PluginVersionResult
    var shouldThrow = false

    init(result: PluginVersionResult = .compatible) {
        self.result = result
    }

    func checkCompatibility() async throws -> PluginVersionResult {
        if shouldThrow {
            throw MockError.anyError
        }
        return result
    }
}
