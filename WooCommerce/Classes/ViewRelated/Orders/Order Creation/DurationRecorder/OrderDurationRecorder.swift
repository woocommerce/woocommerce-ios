import Foundation

enum OrderDurationRecorderError: Error {
    case noStartRecordingTimestamp
    case durationExceededTimeout
}

class OrderDurationRecorder {
    static let shared = OrderDurationRecorder()
    private var orderAddNewTimestamp: TimeInterval?
    private var cardPaymentStartedTimestamp: TimeInterval?
    private static let timeout = 60*10

    private init() { }

    func startRecording() {
        orderAddNewTimestamp = Date().timeIntervalSince1970
    }

    func recordCardPaymentStarted() {
        cardPaymentStartedTimestamp = Date().timeIntervalSince1970
    }

    func reset() {
        orderAddNewTimestamp = nil
        cardPaymentStartedTimestamp = nil
    }

    func timeIntervalSinceOrderAddNew() throws -> Int64 {
        try timeIntervalSince(orderAddNewTimestamp)
    }

    func timeIntervalSinceCardPaymentStarted() throws -> Int64 {
        try timeIntervalSince(cardPaymentStartedTimestamp)
    }

    private func timeIntervalSince(_ origin: TimeInterval?) throws -> Int64 {
        guard let startTimestamp = origin else {
            throw OrderDurationRecorderError.noStartRecordingTimestamp
        }

        let timestamp = Int64(Date().timeIntervalSince1970 - startTimestamp)

        guard timestamp < OrderDurationRecorder.timeout else {
            throw OrderDurationRecorderError.durationExceededTimeout
        }

        return timestamp
    }
}
