import Foundation

protocol TimeProvider {
    func now() -> Date
    func scheduleTimer(timeInterval: TimeInterval, target: Any, selector: Selector) -> Timer
}

struct DefaultTimeProvider: TimeProvider {
    func now() -> Date {
        Date()
    }

    func scheduleTimer(timeInterval: TimeInterval, target: Any, selector: Selector) -> Timer {
        return Timer.scheduledTimer(timeInterval: timeInterval, target: target, selector: selector, userInfo: nil, repeats: false)
    }
}
