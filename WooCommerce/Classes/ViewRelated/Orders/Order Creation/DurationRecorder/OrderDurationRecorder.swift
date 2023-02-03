import Foundation

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
class OrderDurationRecorder: OrderDurationRecorderProtocol {
    static let shared = OrderDurationRecorder()
    private var orderAddNewTimestamp: TimeInterval?
    private var cardPaymentStartedTimestamp: TimeInterval?
    private static let timeout: TimeInterval = 60*10

    private init() { }

    func startRecording() {
        orderAddNewTimestamp = ProcessInfo.processInfo.systemUptime
    }

    func recordCardPaymentStarted() {
        cardPaymentStartedTimestamp = ProcessInfo.processInfo.systemUptime
    }

    func reset() {
        orderAddNewTimestamp = nil
        cardPaymentStartedTimestamp = nil
    }

    func millisecondsSinceOrderAddNew() throws -> Int64 {
        try millisecondsSince(orderAddNewTimestamp)
    }

    func millisecondsSinceCardPaymentStarted() throws -> Int64 {
        try millisecondsSince(cardPaymentStartedTimestamp)
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
