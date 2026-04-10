import Foundation

public protocol TimeProvider {
    func now() -> Date
    func scheduleTimer(timeInterval: TimeInterval, target: Any, selector: Selector) -> Timer
}

public struct DefaultTimeProvider: TimeProvider {
    public init() {}

    public func now() -> Date {
        Date()
    }

    public func scheduleTimer(timeInterval: TimeInterval, target: Any, selector: Selector) -> Timer {
        return Timer.scheduledTimer(timeInterval: timeInterval, target: target, selector: selector, userInfo: nil, repeats: false)
    }
}
