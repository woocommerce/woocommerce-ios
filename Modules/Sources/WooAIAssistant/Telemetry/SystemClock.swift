import Foundation

public protocol SystemClock: Sendable {
    func nowMs() -> Int64
}

public struct WallSystemClock: SystemClock {
    public init() {}

    public func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }
}
