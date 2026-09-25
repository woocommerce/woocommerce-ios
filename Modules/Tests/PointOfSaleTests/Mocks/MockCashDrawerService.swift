import Foundation
import protocol Yosemite.CashDrawerService

final class MockCashDrawerService: CashDrawerService {
    /// Error thrown by `openCashDrawer()`, if any.
    var openError: Error?

    private(set) var openCallCount = 0

    func openCashDrawer() async throws {
        openCallCount += 1
        if let openError {
            throw openError
        }
    }
}
