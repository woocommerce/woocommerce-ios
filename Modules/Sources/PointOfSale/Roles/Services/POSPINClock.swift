import Foundation

protocol POSPINClock: Sendable {
    func now() throws -> TimeInterval
}

struct SystemPOSPINClock: POSPINClock {
    private let origin = ContinuousClock.now

    func now() throws -> TimeInterval {
        // The sample is used only in this service's lifetime. No time is credited across process death.
        let elapsed = origin.duration(to: .now).components
        return Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1_000_000_000_000_000_000
    }
}
