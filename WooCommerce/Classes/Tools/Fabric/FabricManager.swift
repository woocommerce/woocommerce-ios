import Foundation
import UIKit

import CocoaLumberjack
import Crashlytics
import Fabric
import Yosemite



/// FabricManager: Encapsulates all of the Fabric SDK Setup.
///
class FabricManager {

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Initializes the Fabric SDK.
    ///
    func initialize() {
        startCrashlyticsIfNeeded()
    }

    /// Starts Crashlytics
    ///
    func startCrashlyticsIfNeeded() {
        initializeOptOutTracking()

        if !userHasOptedOut() {
            Fabric.with([Crashlytics.self])
            startListeningToAuthNotifications()
        }
    }

    /// Starts listening to Authentication Notifications: Fabric's metadata will be refreshed accordingly.
    ///
    func startListeningToAuthNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(defaultAccountWasUpdated), name: .defaultAccountWasUpdated, object: nil)
    }

    /// Stops listening to Authentication Notifications
    /// after tracking opt-out event
    func stopListeningToAuthNotifications() {
        let nc = NotificationCenter.default
        nc.removeObserver(self, name: .defaultAccountWasUpdated, object: nil)
    }

    /// Handles the `.sessionWasAuthenticated` notification.
    ///
    @objc func defaultAccountWasUpdated(sender: Notification) {
        let account = sender.object as? Yosemite.Account
        let crashlytics = Crashlytics.sharedInstance()

        crashlytics.setUserName(account?.username)
        crashlytics.setUserEmail(account?.email)
        crashlytics.setUserIdentifier(account?.userID.description)

        if let username = account?.username {
            DDLogInfo("🌡 Fabric Account: [\(username)]")
        } else {
            DDLogInfo("🌡 Fabric Account Nuked!")
        }
    }

    /// Clears Crashlytics data after opt-out of tracking event
    ///
    func clearCrashlyticsParameters() {
        let crashlytics = Crashlytics.sharedInstance()

        crashlytics.setUserName(nil)
        crashlytics.setUserEmail(nil)
        crashlytics.setUserIdentifier(nil)
    }
}


// Mark: - Tracking Opt Out
//
extension FabricManager {
    /// Initialize the opt-out tracking
    ///
    func initializeOptOutTracking() {
        if userHasOptedOutIsSet() {
            // We've already configured the opt out setting
            return
        }

        // set the default to no, user has not opted out yet
        setUserHasOptedOutValue(false)
    }

    func userHasOptedOutIsSet() -> Bool {
        return UserDefaults.standard.object(forKey: UserDefaults.Key.userOptedOutOfCrashlytics) != nil
    }

    /// This method just sets the user defaults value for UserOptedOut and doesn't
    /// do any additional configuration of sessions or trackers.
    func setUserHasOptedOutValue(_ optedOut: Bool) {
        UserDefaults.standard.set(optedOut, forKey: UserDefaults.Key.userOptedOutOfCrashlytics)
    }

    func userHasOptedOut() -> Bool {
        return UserDefaults.standard.bool(forKey: UserDefaults.Key.userOptedOutOfCrashlytics.rawValue)
    }

    func setUserHasOptedOut(_ optedOut: Bool) {
        if userHasOptedOutIsSet() {
            let currentValue = userHasOptedOut()
            if currentValue == optedOut {
                return
            }
        }

        // store the preference
        setUserHasOptedOutValue(optedOut)

        // now take action on the preference
        if (optedOut) {
            clearCrashlyticsParameters()
            stopListeningToAuthNotifications()
            DDLogInfo("🔴 Crashlytics opt-out complete.")
        } else {
            startCrashlyticsIfNeeded()
            DDLogInfo("🔵 Crashlytics reporting restored.")
        }
    }
}
