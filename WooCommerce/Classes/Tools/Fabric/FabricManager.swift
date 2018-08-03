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
        Fabric.with([Crashlytics.self])
    }

    /// Starts listening to Authentication Notifications: Fabric's metadata will be refreshed accordingly.
    ///
    func startListeningToAuthNotifications() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(defaultAccountWasUpdated), name: .defaultAccountWasUpdated, object: nil)
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
}
