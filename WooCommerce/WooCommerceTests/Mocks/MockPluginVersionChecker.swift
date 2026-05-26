import Foundation
@testable import WooCommerce

final class MockPluginVersionChecker: PluginVersionCheckerProtocol {
    var result: Result<PluginVersionResult, Error> = .success(.compatible)
    var onCheckCompatibility: (() -> Void)?

    func checkCompatibility() async throws -> PluginVersionResult {
        onCheckCompatibility?()
        return try result.get()
    }
}
