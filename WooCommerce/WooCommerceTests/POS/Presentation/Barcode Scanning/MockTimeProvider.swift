import Foundation
@testable import WooCommerce

final class MockTimeProvider: TimeProvider {
    private var currentTime: Date

    init(startTime: Date = Date(timeIntervalSince1970: 0)) {
        self.currentTime = startTime
    }

    func now() -> Date {
        currentTime
    }

    func advance(by interval: TimeInterval) {
        currentTime = currentTime.addingTimeInterval(interval)
    }
}
