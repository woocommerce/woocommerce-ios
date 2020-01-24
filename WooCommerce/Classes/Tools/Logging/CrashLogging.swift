import Foundation
import AutomatticTracks
import Yosemite

class WCCrashLoggingDataProvider: CrashLoggingDataProvider {

    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateCrashLoggingSystem(_:)), name: .defaultAccountWasUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCrashLoggingSystem(_:)), name: .logOutEventReceived, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateCrashLoggingSystem(_:)), name: .StoresManagerDidUpdateDefaultSite, object: nil)
    }

    var userHasOptedOut: Bool {
        return !CrashLoggingSettings.didOptIn
    }

    var currentUser: TracksUser? {

        guard let account = ServiceLocator.stores.sessionManager.defaultAccount else {
            return nil
        }

        return TracksUser(userID: "\(account.userID)", email: account.email, username: account.username)
    }

    var sentryDSN: String {
        return ApiCredentials.sentryDSN
    }

    var buildType: String {
        return BuildConfiguration.current.rawValue
    }

    @objc func updateCrashLoggingSystem(_ notification: Notification) {
        /// Bumping this call to a later run loop is a little bit hack-y, but because the `StoresManager` fires the events
        /// we're interested as part of its initialization, we need to wait for that initalization to be complete before
        /// taking action – otherwise the application will deadlock.
        DispatchQueue.main.async {
            CrashLogging.setNeedsDataRefresh()
        }
    }
}

struct CrashLoggingSettings {
    static var didOptIn: Bool {
        get {
            // By default, opt the user into crash reporting
            return UserDefaults.standard.object(forKey: .userOptedInCrashLogging) ?? true
        }
        set {
            if newValue {
                DDLogInfo("🔵 Crash Logging reporting restored.")
            }
            else {
                DDLogInfo("🔴 Crash Logging opt-out complete.")
            }

            UserDefaults.standard.set(newValue, forKey: .userOptedInCrashLogging)
        }
    }
}
