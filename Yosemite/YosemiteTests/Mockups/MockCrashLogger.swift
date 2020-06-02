import Storage

struct MockCrashLogger: CrashLogger {
    func logMessageAndWait(_ message: String, properties: [String: Any]?, level: SeverityLevel) {
        // no-op
    }
}
