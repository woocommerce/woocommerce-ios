import Foundation

/// Throttler class
/// 
/// To throttle a function means to ensure that the function is called at most once in a specified time period (for instance, once every 10 seconds).
/// Throttle function must be called at each change of the state.
/// (eg: in a search box you may want call it on textDidChange)
///
final class Throttler {

    private let queue: DispatchQueue = DispatchQueue.global(qos: .background)

    private var job: DispatchWorkItem = DispatchWorkItem(block: {})
    private var previousRun: Date = Date.distantPast
    private var maxInterval: Double

    init(seconds: Double) {
        self.maxInterval = seconds
    }

    func throttle(block: @escaping () -> ()) {
        cancel()
        job = DispatchWorkItem() { [weak self] in
            self?.previousRun = Date()
            block()
        }
        let delay = maxInterval.isLess(than: Date.second(from: previousRun)) ? 0 : maxInterval
        queue.asyncAfter(deadline: .now() + Double(delay), execute: job)
    }

    func cancel() {
        job.cancel()
    }
}

private extension Date {
    static func second(from referenceDate: Date) -> Double {
        return Date().timeIntervalSince(referenceDate)
    }
}
