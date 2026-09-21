import Foundation

public protocol SystemClock: Sendable {
    func nowMs() -> Int64
}

public struct MonotonicSystemClock: SystemClock {
    public init() {}

    // Monotonic source so durations stay correct when wall clock jumps (NTP sync, manual time changes).
    public func nowMs() -> Int64 {
        Int64(ProcessInfo.processInfo.systemUptime * 1000)
    }
}
