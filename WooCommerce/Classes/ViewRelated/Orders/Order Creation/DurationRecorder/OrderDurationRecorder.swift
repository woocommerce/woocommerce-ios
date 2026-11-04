import Foundation
import Synchronization

enum OrderDurationRecorderError: Error {
    case noStartRecordingTimestamp
    case durationExceededTimeout
}

protocol OrderDurationRecorderProtocol {
    func startRecording()
    func recordCardPaymentStarted()
    func reset()
    func millisecondsSinceOrderAddNew() throws -> Int64
    func millisecondsSinceCardPaymentStarted() throws -> Int64
}

/// Measures the duration of Order Creation and In-Person Payments flows for analytical purposes
///
final class OrderDurationRecorder: OrderDurationRecorderProtocol, Sendable {
    static let shared = OrderDurationRecorder()
    private let timestamps = Mutex(Timestamps())
    private static let timeout: TimeInterval = 60*10

    private init() { }

    func startRecording() {
        let now = ProcessInfo.processInfo.systemUptime
        timestamps.withLock { $0.orderAddNew = now }
    }

    func recordCardPaymentStarted() {
        let now = ProcessInfo.processInfo.systemUptime
        timestamps.withLock { $0.cardPaymentStarted = now }
    }

    func reset() {
        timestamps.withLock { $0 = Timestamps() }
    }

    func millisecondsSinceOrderAddNew() throws -> Int64 {
        try millisecondsSince(timestamps.withLock { $0.orderAddNew })
    }

    func millisecondsSinceCardPaymentStarted() throws -> Int64 {
        try millisecondsSince(timestamps.withLock { $0.cardPaymentStarted })
    }

    private func millisecondsSince(_ origin: TimeInterval?) throws -> Int64 {
        guard let startTimestamp = origin else {
            throw OrderDurationRecorderError.noStartRecordingTimestamp
        }

        let timestamp = ProcessInfo.processInfo.systemUptime - startTimestamp

        guard timestamp < OrderDurationRecorder.timeout else {
            throw OrderDurationRecorderError.durationExceededTimeout
        }

        return Int64(timestamp*1000)
    }
}

private extension OrderDurationRecorder {
    struct Timestamps {
        var orderAddNew: TimeInterval?
        var cardPaymentStarted: TimeInterval?
    }
}
