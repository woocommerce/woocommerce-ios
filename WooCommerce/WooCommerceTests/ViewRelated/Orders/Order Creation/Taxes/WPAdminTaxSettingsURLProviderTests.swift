import XCTest
@testable import WooCommerce
import WooFoundation
import Yosemite

final class WPAdminTaxSettingsURLProviderTests: XCTestCase {
    func test_wpAdminTaxSettingsURL_passes_right_url() {
        // Given
        let sampleAdminURL = "https://testshop.com/wp-admin/"
        let sessionManager = SessionManager.testingInstance
        let site = Site.fake().copy(adminURL: sampleAdminURL)
        sessionManager.defaultSite = site
        let stores = MockStoresManager(sessionManager: sessionManager)

        let sut = WPAdminTaxSettingsURLProvider(stores: stores)

        let expectedURLString = sampleAdminURL + "admin.php?page=wc-settings&tab=tax"

        // Then
        XCTAssertEqual(sut.provideWpAdminTaxSettingsURL()?.absoluteString, expectedURLString)
    }
}
