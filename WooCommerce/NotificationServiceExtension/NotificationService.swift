import Foundation
import UserNotifications

final class NotificationService: UNNotificationServiceExtension {

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        let content = request.content
        if shouldBlockNotifications(with: content) {
            return
        }
        contentHandler(content)
    }
    
    override func serviceExtensionTimeWillExpire() {
        // No-op
    }
}

private extension NotificationService {
    func shouldBlockNotifications(with content: UNNotificationContent) -> Bool {
        let userInfo = content.userInfo
        let registeredSites = UserDefaults.standard.string(forKey: Constants.registeredIDsKey)?
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
        static let registeredIDsKey = "siteIDsRegisteredForWooPushNotifications"
    }
}
