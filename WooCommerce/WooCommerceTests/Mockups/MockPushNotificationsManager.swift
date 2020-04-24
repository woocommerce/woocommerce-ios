
import Foundation
import UIKit
@testable import WooCommerce

final class MockPushNotificationsManager: PushNotesManager {

    var foregroundNotifications: Observable<ForegroundNotification> {
        foregroundNotificationsSubject
    }

    private let foregroundNotificationsSubject = PublishSubject<ForegroundNotification>()

    func resetBadgeCount() {

    }

    func registerForRemoteNotifications() {

    }

    func unregisterForRemoteNotifications() {

    }

    func ensureAuthorizationIsRequested(onCompletion: ((Bool) -> ())?) {

    }

    func registrationDidFail(with error: Error) {

    }

    func registerDeviceToken(with tokenData: Data, defaultStoreID: Int64) {

    }

    func handleNotification(_ userInfo: [AnyHashable: Any], completionHandler: @escaping (UIKit.UIBackgroundFetchResult) -> ()) {

    }
}

extension MockPushNotificationsManager {
    /// Send a ForegroundNotification that will be emitted by the `foregroundNotifications`
    /// observable.
    ///
    func sendForegroundNotification(_ notification: ForegroundNotification) {
        foregroundNotificationsSubject.send(notification)
    }
}
