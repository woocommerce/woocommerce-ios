struct MockCrashLogger: CrashLogger {
    func logError(_ error: Error, userInfo: [String: Any]?, level: SeverityLevel) {
        // no-op
    }

    func logFatalErrorAndExit(_ error: Error, userInfo: [String: Any]?) -> Never {
        print(error.localizedDescription)
        while true {} // Avoid returning from a Never function
    }

    func logMessage(_ message: String, properties: [String: Any]?, level: SeverityLevel) {
        // no-op
    }

    func logMessageAndWait(_ message: String, properties: [String: Any]?, level: SeverityLevel) {
        // no-op
    }
}
