import Foundation
import AutomatticTracks
import Clibsodium // missing required mododule 'Clibsodium' in Storage and Networking?

struct CommonCrashLogger: CrashLogger {

    // Usage of AutomatticTracks.CrashLogger (Sentry integration)
    init() {

        let dataProvider = CommonCrashLoggerDataProvider()

        let crashLogger = AutomatticTracks.CrashLogging(
            dataProvider: dataProvider,
            eventLogging: nil)
    }

    // CrahLogger conformance
    func logMessage(_ message: String, properties: [String : Any]?, level: SeverityLevel) {}

    func logError(_ error: Error, userInfo: [String : Any]?, level: SeverityLevel) {}

    func logFatalErrorAndExit(_ error: Error, userInfo: [String : Any]?) -> Never {
        fatalError()
    }
}

// Our data provider that must conform to AutomatticTrack's CrashLoggingDataProvider.
class CommonCrashLoggerDataProvider: CrashLoggingDataProvider {
    var sentryDSN: String = "" // Mobile-secrets

    var userHasOptedOut: Bool = false

    var buildType: String = ""

    var currentUser: TracksUser? // We can't use it or we would need to import Yosemite & WooCommerce modules -> In this case Sentry would track the error but not the user and would show as anonymous.

}
