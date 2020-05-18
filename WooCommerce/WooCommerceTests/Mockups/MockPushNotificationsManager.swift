
import Foundation
import UIKit
@testable import WooCommerce
import Yosemite

final class MockPushNotificationsManager: PushNotesManager {

    var foregroundNotifications: Observable<PushNotification> {
        foregroundNotificationsSubject
    }

    private let foregroundNotificationsSubject = PublishSubject<PushNotification>()

    var inactiveNotifications: Observable<PushNotification> {
        inactiveNotificationsSubject
    }

    private let inactiveNotificationsSubject = PublishSubject<PushNotification>()

    func resetBadgeCount(type: Note.Kind) {

    }

    func resetBadgeCountForAllStores(onCompletion: @escaping () -> Void) {

    }

    func reloadBadgeCount() {

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

    func handleNotification(_ userInfo: [AnyHashable: Any],
                            onBadgeUpdateCompletion: @escaping () -> Void,
                            completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {

    }
}

extension MockPushNotificationsManager {
    /// Send a `PushNotification` that will be emitted by the `foregroundNotifications`
    /// observable.
    ///
    func sendForegroundNotification(_ notification: PushNotification) {
        foregroundNotificationsSubject.send(notification)
    }
}
