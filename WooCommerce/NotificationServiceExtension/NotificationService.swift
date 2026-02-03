import Foundation
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        if shouldSuppressNotifications(with: request.content.userInfo) {
            let silentContent = UNMutableNotificationContent()
            contentHandler(silentContent)
            UNUserNotificationCenter.current().removeDeliveredNotifications(
                withIdentifiers: [request.identifier]
            )
            return
        }
        contentHandler(request.content)
    }
}

private extension NotificationService {
    func shouldSuppressNotifications(with userInfo: [AnyHashable: Any]) -> Bool {
        let registeredSites = UserDefaults(suiteName: Constants.appGroupID)?.string(forKey: Constants.registeredIDsKey)?
            .components(separatedBy: ",")
            .compactMap { Int64($0) }

        if let siteID = userInfo[Constants.APNSKey.siteID] as? Int64,
           let _ = userInfo[Constants.APNSKey.noteID] as? Int64,
           registeredSites?.contains(siteID) == true {
            return true
        }
        return false
    }

    enum Constants {
        enum APNSKey {
            static let siteID = "blog"
            static let noteID = "note_id"
        }
        static let appGroupID = "group.com.automattic.woocommerce"
        static let registeredIDsKey = "siteIDsRegisteredForWooPushNotifications"
    }
}
