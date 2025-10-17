import Foundation
@testable import PointOfSale
import WooFoundation

final class MockTimer: Timer {
    var isCancelled = false
    weak var mockTimeProvider: MockTimeProvider?
    let timerInterval: TimeInterval
    let target: Any
    let selector: Selector
    let repeats: Bool

    init(timeInterval: TimeInterval, target: Any, selector: Selector, mockTimeProvider: MockTimeProvider) {
        self.timerInterval = timeInterval
        self.target = target
        self.selector = selector
        self.repeats = false
        self.mockTimeProvider = mockTimeProvider
        super.init()
    }

    override func invalidate() {
        isCancelled = true
        mockTimeProvider?.removeTimer(self)
    }
}

final class MockTimeProvider: TimeProvider {
    private var currentTime: Date
    private var activeTimers: [MockTimer] = []

    init(startTime: Date = Date(timeIntervalSince1970: 0)) {
        self.currentTime = startTime
    }

    func now() -> Date {
        currentTime
    }

    func advance(by interval: TimeInterval) {
        currentTime = currentTime.addingTimeInterval(interval)

        // Check and fire any timers that should have triggered during this time advancement
        let timersToFire = activeTimers.filter { !$0.isCancelled && $0.timerInterval <= interval }
        for timer in timersToFire {
            _ = (timer.target as AnyObject).perform(timer.selector, with: timer.userInfo)
            if !timer.repeats {
                removeTimer(timer)
            }
        }
    }

    func scheduleTimer(timeInterval: TimeInterval, target: Any, selector: Selector) -> Timer {
        let mockTimer = MockTimer(
            timeInterval: timeInterval,
            target: target,
            selector: selector,
            mockTimeProvider: self
        )
        activeTimers.append(mockTimer)
        return mockTimer
    }

    func removeTimer(_ timer: MockTimer) {
        activeTimers.removeAll { $0 === timer }
    }

    func clearScheduledTimers() {
        activeTimers.removeAll()
    }
}
