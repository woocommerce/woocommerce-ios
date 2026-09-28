import Foundation
import protocol Yosemite.CashDrawerService

final class MockCashDrawerService: CashDrawerService {
    /// Error thrown by `openCashDrawer()`, if any.
    var openError: Error?

    private(set) var openCallCount = 0

    /// Fired on every open, so tests can wait for an open that runs in its own task.
    var onOpen: (() -> Void)?

    /// Emits drawer sensor signals to the controller under test.
    let (drawerSignals, drawerSignalsContinuation) = AsyncStream.makeStream(of: Bool.self)

    func drawerSignalUpdates() -> AsyncStream<Bool> {
        drawerSignals
    }

    func openCashDrawer() async throws {
        openCallCount += 1
        onOpen?()
        if let openError {
            throw openError
        }
    }
}
