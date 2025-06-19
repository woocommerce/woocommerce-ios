import Foundation
@testable import WooCommerce

final class MockTimeProvider: TimeProvider {
    private var currentTime: Date

    init(startTime: Date = Date()) {
        self.currentTime = startTime
    }

    func now() -> Date {
        currentTime
    }

    func advance(by interval: TimeInterval) {
        currentTime = currentTime.addingTimeInterval(interval)
    }
}
