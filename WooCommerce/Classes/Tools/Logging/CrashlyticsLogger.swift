import Foundation
import CocoaLumberjack
import Crashlytics

class CrashlyticsLogger: DDAbstractLogger {
    /// Shared Instance
    ///
    static var shared = CrashlyticsLogger()

    override func log(message logMessage: DDLogMessage) {
        var message = logMessage.message

        if let ivar = class_getInstanceVariable(object_getClass(self), "_logFormatter"),
            let logFormatter = object_getIvar(self, ivar) as? DDLogFormatter,
            let formattedMessage = logFormatter.format(message: logMessage) {
            message = formattedMessage
        }

        CLSLogv("%@", getVaList([message]))
    }
}
