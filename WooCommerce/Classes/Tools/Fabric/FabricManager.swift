import Foundation
import UIKit

//import Crashlytics
//import Fabric
import Yosemite



/// FabricManager: Encapsulates all of the Fabric SDK Setup.
///
class FabricManager {

    /// Check user opt-in for Crash Reporting
    ///
    var userHasOptedIn: Bool {
        get {
            let optedIn: Bool? = UserDefaults.standard.object(forKey: .userOptedInCrashlytics)
            return optedIn ?? true // crash reports turned on by default
        }
        set {
            UserDefaults.standard.set(newValue, forKey: .userOptedInCrashlytics)
        }
    }

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
        guard userHasOptedIn else {
            return
        }

        //Fabric.with([Crashlytics.self])
        startListeningToAuthNotifications()
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
//        let crashlytics = Crashlytics.sharedInstance()
//
//        crashlytics.setUserName(account?.username)
//        crashlytics.setUserEmail(account?.email)
//        crashlytics.setUserIdentifier(account?.userID.description)

        if let username = account?.username {
            DDLogInfo("🌡 Fabric Account: [\(username)]")
        } else {
            DDLogInfo("🌡 Fabric Account Nuked!")
        }
    }

    /// Clears Crashlytics data after opt-out of tracking event
    ///
    func clearCrashlyticsParameters() {
//        let crashlytics = Crashlytics.sharedInstance()
//
//        crashlytics.setUserName(nil)
//        crashlytics.setUserEmail(nil)
//        crashlytics.setUserIdentifier(nil)
    }
}


// MARK: - Tracking Opt Out
//
extension FabricManager {

    func setUserHasOptedIn(_ optedIn: Bool) {
        userHasOptedIn = optedIn

        if optedIn {
            startCrashlyticsIfNeeded()
            DDLogInfo("🔵 Crashlytics reporting restored.")
        } else {
            clearCrashlyticsParameters()
            stopListeningToAuthNotifications()
            DDLogInfo("🔴 Crashlytics opt-out complete.")
        }
    }
}
