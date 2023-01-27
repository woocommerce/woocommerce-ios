import Foundation

enum OrderDurationRecorderError: Error {
    case noStartRecordingTimestamp
}

class OrderDurationRecorder {
    static let shared = OrderDurationRecorder()
    private var startTimestamp: TimeInterval?

    private init() { }

    func startRecording() {
        startTimestamp = Date().timeIntervalSince1970
    }

    func reset() {
        startTimestamp = nil
    }

    func currentLapse() throws -> Int64 {
        guard let startTimestamp = startTimestamp else {
            throw OrderDurationRecorderError.noStartRecordingTimestamp
        }

        return Int64(Date().timeIntervalSince1970 - startTimestamp)
    }
}
