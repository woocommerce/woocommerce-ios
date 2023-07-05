import XCTest
@testable import WooCommerce

final class UserDefaultWooTests: XCTestCase {

    private var userDefaults: UserDefaults!
    private let uuid = UUID().uuidString

    override func setUpWithError() throws {
        userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        try super.setUpWithError()
    }

    override func tearDown() {
        userDefaults.removeSuite(named: uuid)
        super.tearDown()
    }

    func test_hasDismissedBlazeBanner_returns_false_if_no_value_for_the_provided_site_is_found() throws {
        // Given
        userDefaults[.hasDismissedBlazeBanner] = ["436": true]
        let sampleSiteID: Int64 = 123

        // When
        let hasDismissed = userDefaults.hasDismissedBlazeBanner(for: sampleSiteID)

        // Then
        XCTAssertFalse(hasDismissed)
    }

    func test_hasDismissedBlazeBanner_returns_false_if_the_saved_value_for_the_provided_site_is_false() throws {
        // Given
        let sampleSiteID: Int64 = 123
        userDefaults[.hasDismissedBlazeBanner] = ["\(sampleSiteID)": false]

        // When
        let hasDismissed = userDefaults.hasDismissedBlazeBanner(for: sampleSiteID)

        // Then
        XCTAssertFalse(hasDismissed)
    }

    func test_hasDismissedBlazeBanner_returns_true_if_the_saved_value_for_the_provided_site_is_true() throws {
        // Given
        let sampleSiteID: Int64 = 123
        userDefaults[.hasDismissedBlazeBanner] = ["\(sampleSiteID)": true]

        // When
        let hasDismissed = userDefaults.hasDismissedBlazeBanner(for: sampleSiteID)

        // Then
        XCTAssertTrue(hasDismissed)
    }

    func test_setBlazeBannerDismissed_sets_the_value_for_the_provided_site_to_true() throws {
        // Given
        userDefaults[.hasDismissedBlazeBanner] = ["436": true]
        let sampleSiteID: Int64 = 123

        // When
        userDefaults.setBlazeBannerDismissed(for: sampleSiteID)

        // Then
        let expectedValues = ["436": true, "\(sampleSiteID)": true]
        XCTAssertEqual(userDefaults[.hasDismissedBlazeBanner] as? [String: Bool], expectedValues)
    }
}
