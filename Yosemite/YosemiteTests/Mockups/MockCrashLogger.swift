import Storage

struct MockCrashLogger: CrashLogger {
    func logMessage(_ message: String, properties: [String : Any]?, level: SeverityLevel) {
        // no-op
    }
}
