import Foundation

public protocol Scheduler {
    func schedule(after seconds: TimeInterval, action: @escaping () -> Void) -> Cancellable
}

public protocol Cancellable {
    func cancel()
}

extension DispatchWorkItem: Cancellable {}

public class DefaultScheduler: Scheduler {
    public init() { }

    public func schedule(after seconds: TimeInterval, action: @escaping () -> Void) -> Cancellable {
        let workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: workItem)
        return workItem
    }
}
