import Foundation
@testable import WooCommerce

final class MockPluginVersionChecker: PluginVersionCheckerProtocol {
    var result: Result<PluginVersionResult, Error> = .success(.compatible)

    func checkCompatibility() async throws -> PluginVersionResult {
        try result.get()
    }
}
