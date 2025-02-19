import Foundation
import protocol Yosemite.StoresManager

protocol PushNotificationBackgroundSynchronizerFactoryProtocol {
    func make(userInfo: [AnyHashable: Any], stores: StoresManager) -> PushNotificationBackgroundSynchronizerProtocol
}

struct PushNotificationBackgroundSynchronizerFactory: PushNotificationBackgroundSynchronizerFactoryProtocol {
    func make(userInfo: [AnyHashable: Any], stores: StoresManager) -> any PushNotificationBackgroundSynchronizerProtocol {
        return PushNotificationBackgroundSynchronizer(userInfo: userInfo, stores: stores)
    }
}
