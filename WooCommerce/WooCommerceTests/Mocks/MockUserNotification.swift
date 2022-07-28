import UserNotifications

/// Because `UNNotificationResponse` and `UNNotification` can only be initialized with `init(coder:)`,
/// this `NSCoder` subclass can be used to mock these two classes.
final class MockUserNotificationCoder: NSCoder {
    private enum FieldKey: String {
        case date, request, // `UNNotification`
             notification, actionIdentifier // `UNNotificationResponse`
    }
    private let actionIdentifier: String
    private let request: UNNotificationRequest

    override var allowsKeyedCoding: Bool { true }

    /// - Parameters:
    ///   - actionIdentifier: for `UNNotificationResponse` only.
    ///   - request: the request of `UNNotification` or that of a `UNNotificationResponse`.
    init(actionIdentifier: String = "", request: UNNotificationRequest) {
        self.actionIdentifier = actionIdentifier
        self.request = request
    }

    override func decodeObject(forKey key: String) -> Any? {
        let fieldKey = FieldKey(rawValue: key)
        switch fieldKey {
            // `UNNotification` fields
        case .date:
            return Date()
        case .request:
            return request
            // `UNNotificationResponse` fields
        case .actionIdentifier:
            return actionIdentifier
        case .notification:
            return UNNotification(coder: self)
        default:
            return nil
        }
    }
}

final class MockNotificationContent: UNNotificationContent {
    private let mockUserInfo: [AnyHashable: Any]

    init(userInfo: [AnyHashable: Any]) {
        mockUserInfo = userInfo
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var userInfo: [AnyHashable: Any] {
        mockUserInfo
    }
}

final class MockNotification: UNNotification {
    init?(request: UNNotificationRequest) {
        super.init(coder: MockUserNotificationCoder(request: request))
    }

    convenience init?(userInfo: [AnyHashable: Any]) {
        self.init(request: .init(identifier: "",
                                 content: MockNotificationContent(userInfo: userInfo),
                                 trigger: nil))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

final class MockNotificationResponse: UNNotificationResponse {
    init?(actionIdentifier: String = "", requestIdentifier: String = "", notificationUserInfo: [AnyHashable: Any] = [:]) {
        let request = UNNotificationRequest.init(identifier: requestIdentifier,
                                                 content: MockNotificationContent(userInfo: notificationUserInfo),
                                                 trigger: nil)
        super.init(coder: MockUserNotificationCoder(actionIdentifier: actionIdentifier, request: request))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
