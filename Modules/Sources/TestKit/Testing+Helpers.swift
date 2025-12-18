import Testing

/// This file gathers helper functions for the new Testing framework

public func waitUntil(
    timeoutNanoseconds: UInt64 = 500_000_000,
    _ condition: @escaping @Sendable () -> Bool
) async {
    let start = ContinuousClock.now
    while ContinuousClock.now - start < .nanoseconds(Int(timeoutNanoseconds)) {
        if condition() { return }
        await Task.yield()
    }
    Issue.record("Condition not met before timeout")
}
