import Foundation
@testable import WooCommerce

final class MockPluginVersionChecker: PluginVersionCheckerProtocol {
    var result: Result<PluginVersionResult, Error> = .success(.compatible)
    var onCheckCompatibility: (@MainActor () -> Void)?

    func checkCompatibility() async throws -> PluginVersionResult {
        await onCheckCompatibility?()
        return try result.get()
    }
}
