import Foundation
import StarIO10
@testable import Hardware

final class MockStarPrinterConnection: StarPrinterConnection {
    /// Held strongly, unlike `StarPrinter`, so tests can check the coordinator released it.
    // swiftlint:disable:next weak_delegate
    var printerDelegate: (any PrinterDelegate)?

    /// Runs inside `open()` on the caller's executor, before `open()` returns or throws `openError`.
    var onOpen: (nonisolated(nonsending) () async -> Void)?

    var openError: (any Error)?

    private(set) var closeCallCount = 0

    nonisolated(nonsending) func open() async throws {
        await onOpen?()
        if let openError {
            throw openError
        }
    }

    nonisolated(nonsending) func close() async {
        closeCallCount += 1
    }

    nonisolated(nonsending) func print(command: String) async throws {}
}
