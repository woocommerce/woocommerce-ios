import XCTest
@testable import WooCommerce
@testable import CocoaLumberjack

final class ServiceLocatorTests: XCTestCase {

    func testServiceLocatorProvidesAnalytics() {
        XCTAssertNotNil(ServiceLocator.analytics)
    }

    func testAnalyticsDefaultsToWooAnalytics() {
        let analytics = ServiceLocator.analytics

        XCTAssertTrue(analytics is WooAnalytics)
    }

    func testServiceLocatorProvidesStores() {
        XCTAssertNotNil(ServiceLocator.stores)
    }

    func testStoresDefaultsToStoresManager() {
        let stores = ServiceLocator.stores

        XCTAssertTrue(stores is DefaultStoresManager)
    }

    func testServiceLocatorProvidesNotices() {
        XCTAssertNotNil(ServiceLocator.noticePresenter)
    }

    func testNoticesDefaultsToNoticePresenter() {
        let notices = ServiceLocator.noticePresenter

        XCTAssertTrue((notices as Any) is NoticePresenter)
    }

    func testServiceLocatorProvidesPushNotificationsManager() {
        XCTAssertNotNil(ServiceLocator.pushNotesManager)
    }

    func testPushNotesManagerDefaultsToPushNotificationsManager() {
        let pushNotes = ServiceLocator.pushNotesManager

        XCTAssertTrue(pushNotes is PushNotificationsManager)
    }

    func testServiceLocatorProvidesAuthenticationManager() {
        XCTAssertNotNil(ServiceLocator.authenticationManager)
    }

    func testAutenticationManagerDefaultsAuthenticationManager() {
        let authentication = ServiceLocator.authenticationManager

        XCTAssertTrue(authentication is AuthenticationManager)
    }

    func testServiceLocatorProvidesShippingSettingsService() {
        XCTAssertNotNil(ServiceLocator.shippingSettingsService)
    }

    func testServiceLocatorProvidesStorageManager() {
        XCTAssertNotNil(ServiceLocator.storageManager)
    }

    func testServiceLocatorProvidesLogger() {
        XCTAssertNotNil(ServiceLocator.fileLogger)
    }

    func testServiceLocatorProvidesKeyboardStateProvider() {
        XCTAssertNotNil(ServiceLocator.keyboardStateProvider)
        XCTAssertTrue(ServiceLocator.keyboardStateProvider is KeyboardStateProvider)
    }

    func testFileLoggerDefaultsToDDFileLogger() {
        let fileLogger = ServiceLocator.fileLogger

        XCTAssertTrue(fileLogger is DDFileLogger)
    }
}
