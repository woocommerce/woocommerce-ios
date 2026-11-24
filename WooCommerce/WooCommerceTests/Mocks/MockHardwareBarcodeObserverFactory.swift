import Foundation
import enum Hardware.HIDBarcodeParserResult
@testable import WooCommerce

@MainActor
final class MockHardwareBarcodeObserverFactory {
    private(set) var createdObserverCount = 0
    var lastObserver: AnyObject?
    private var acceptsInputHandler: () -> Bool = { false }
    private var onResult: (HIDBarcodeParserResult) -> Void = { _ in }

    func make(acceptsInput: @escaping () -> Bool, onResult: @escaping (HIDBarcodeParserResult) -> Void) -> AnyObject {
        createdObserverCount += 1
        acceptsInputHandler = acceptsInput
        self.onResult = onResult
        let observer = NSObject()
        lastObserver = observer
        return observer
    }

    func acceptsInput() -> Bool {
        acceptsInputHandler()
    }

    func send(_ result: HIDBarcodeParserResult) {
        onResult(result)
    }
}
