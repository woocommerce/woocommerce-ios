import Foundation

enum OrderDurationRecorderError: Error {
    case noStartRecordingTimestamp
    case durationExceededTimeout
}

/// Measures the duration of Order Creation and In-Person Payments flows for analytical purposes
///
class OrderDurationRecorder {
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

    func milisecondsSinceOrderAddNew() throws -> Int64 {
        try milisecondsSince(orderAddNewTimestamp)
    }

    func milisecondsSinceCardPaymentStarted() throws -> Int64 {
        try milisecondsSince(cardPaymentStartedTimestamp)
    }

    private func milisecondsSince(_ origin: TimeInterval?) throws -> Int64 {
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
