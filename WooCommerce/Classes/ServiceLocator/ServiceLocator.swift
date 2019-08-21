import Foundation
import CocoaLumberjack
import Storage


/// Provides global depedencies.
///
final class ServiceLocator {
    private static var _analytics: Analytics = WooAnalytics(analyticsProvider: TracksProvider())
    private static var _stores: StoresManager = DefaultStoresManager(sessionManager: .standard)

    /// WordPressAuthenticator Wrapper
    ///
    private static var _authenticationManager = AuthenticationManager()

    /// In-App Notifications Presenter
    ///
    private static var _noticePresenter = NoticePresenter()

    /// Push Notifications Manager
    ///
    private static var _pushNotesManager = PushNotificationsManager()

    /// CoreData Stack
    ///
    private static var _storageManager = CoreDataManager(name: WooConstants.databaseStackName)

    /// Cocoalumberjack DDLog
    /// The type definition is needed because DDFilelogger doesn't have a nullability specifier (but is still a non-optional).
    ///
    private static var _fileLogger: DDFileLogger = DDFileLogger()

    /// Provides the access point to the analytics.
    /// - Returns: An implementation of the Analytics protocol. It defaults to WooAnalytics
    static var analytics: Analytics {
        return _analytics
    }

    /// Provides the access point to the stores.
    /// - Returns: An implementation of the StoresManager protocol. It defaults to DefaultStoresManager
    static var stores: StoresManager {
        return _stores
    }

    /// Provides the access point to the NoticePresenter.
    /// - Returns: An implementation of the NoticePresenter protocol. It defaults to DefaultNoticePresenter
    static var noticePresenter: Notices {
        return _noticePresenter
    }

    /// Provides the access point to the PushNotesManager.
    /// - Returns: An implementation of the PushNotesManager protocol. It defaults to PushNotificationsManager
    static var pushNotesManager: PushNotesManager {
        return _pushNotesManager
    }

    /// Provides the access point to the AuthenticationManager.
    /// - Returns: An implementation of the AuthenticationManager protocol. It defaults to DefaultAuthenticationManager
    static var authenticationManager: Authentication {
        return _authenticationManager
    }
}


// MARK: - Testability

/// The setters declared in this extension are meant to be used only from the test bundle
extension ServiceLocator {
    static func setAnalytics(_ mock: Analytics) {
        guard isRunningTests() else {
            return
        }

        _analytics = mock
    }

    static func setStores(_ mock: StoresManager) {
        guard isRunningTests() else {
            return
        }

        _stores = mock
    }
}


private extension ServiceLocator {
    static func isRunningTests() -> Bool {
        return NSClassFromString("XCTestCase") != nil
    }
}
