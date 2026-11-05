import Foundation
import StarIO10
@testable import Hardware

final class MockStarPrinterConnection: StarPrinterConnection {
    /// Held strongly, unlike `StarPrinter`, so tests can check the coordinator released it.
    // swiftlint:disable:next weak_delegate
    var printerDelegate: (any PrinterDelegate)?

    /// Runs inside `open()`, before it succeeds.
    var onOpen: (() -> Void)?

    private(set) var closeCallCount = 0

    func open() async throws {
        onOpen?()
    }

    func close() async {
        closeCallCount += 1
    }

    func print(command: String) async throws {}
}
