import Storage

struct MockCrashLogger: CrashLogger {
    func logError(_ error: Error, userInfo: [String: Any]?, level: SeverityLevel) {
        // no-op
    }

    func logErrorAndWait(_ error: Error, userInfo: [String: Any]?, level: SeverityLevel) {
        // no-op
    }

    func logMessage(_ message: String, properties: [String: Any]?, level: SeverityLevel) {
        // no-op
    }

    func logMessageAndWait(_ message: String, properties: [String: Any]?, level: SeverityLevel) {
        // no-op
    }
}
