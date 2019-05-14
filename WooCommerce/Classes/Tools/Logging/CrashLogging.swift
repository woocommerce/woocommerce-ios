import Foundation
import UIKit

import AutomatticTracks
import Yosemite


/// CrashLoggingManager: Performs the app-specific tasks required for crash logging.
///
class WCCrashLoggingDataProvider: CrashLoggingDataProvider {

    init() {
        self.startListeningToAuthNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Check user opt-in for Crash Reporting
    ///
    var userHasOptedOut: Bool {
        get {
            guard let userHasOptedIn = UserDefaults.standard.bool(forKey: .userOptedInCrashLogging) else {
                return false // crash reports turned on by default
            }

            return !userHasOptedIn
        }
        set {
            UserDefaults.standard.set(newValue, forKey: .userOptedInCrashLogging)

            if newValue {
                DDLogInfo("🔴 Crash Logging opt-out complete.")
            }
            else {
                DDLogInfo("🔵 Crash Logging reporting restored.")
            }
        }
    }

    fileprivate var wooAccount: Yosemite.Account!

    var currentUser: TracksUser? {
        guard wooAccount != nil else {
            return nil
        }

        return TracksUser(userID: "\(wooAccount.userID)", email: wooAccount.email, username: wooAccount.username)
    }

    var sentryDSN: String {
        return ApiCredentials.sentryDSN
    }

    var buildType: String {
        return BuildConfiguration.current.rawValue
    }
}

extension WCCrashLoggingDataProvider {
    /// Starts listening to Authentication Notifications
    ///
    func startListeningToAuthNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(defaultAccountWasUpdated), name: .defaultAccountWasUpdated, object: nil)
    }

    /// Handles the `.sessionWasAuthenticated` notification.
    ///
    @objc func defaultAccountWasUpdated(sender: Notification) {
        let account = sender.object as? Yosemite.Account
        self.wooAccount = account

        if let username = account?.username {
            DDLogInfo("🌡 Tracks Account: [\(username)]")
        } else {
            DDLogInfo("🌡 Tracks Account Nuked!")
        }
    }
}
