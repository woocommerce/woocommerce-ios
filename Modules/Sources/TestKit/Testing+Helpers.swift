import Testing

/// This file gathers helper functions for the new Testing framework

public func waitForCondition(
    timeoutNanoseconds: UInt64 = 500_000_000,
    _ condition: @escaping @Sendable () -> Bool
) async -> Bool {
    let start = ContinuousClock.now

    while ContinuousClock.now - start < .nanoseconds(Int(timeoutNanoseconds)) {
        if condition() {
            return true
        }
        await Task.yield()
    }

    return false
}
