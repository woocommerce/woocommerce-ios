import XCTest
@testable import WooCommerce

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
}
