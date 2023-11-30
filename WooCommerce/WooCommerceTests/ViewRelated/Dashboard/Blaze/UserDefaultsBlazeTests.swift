import XCTest
@testable import WooCommerce

final class UserDefaultsBlazeTests: XCTestCase {

    private let sampleSiteID: Int64 = 123

    func test_hasDismissedBlazeSectionOnMyStore_returns_correct_value() throws {
        // Given
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        userDefaults[.hasDismissedBlazeSectionOnMyStore] = ["\(sampleSiteID)": false]

        // When
        let hasDismissed = userDefaults.hasDismissedBlazeSectionOnMyStore(for: sampleSiteID)

        // Then
        XCTAssertFalse(hasDismissed)
    }

    func test_restoreBlazeSectionOnMyStore_sets_the_blaze_section_to_be_not_dismissed() throws {
        // Given
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        userDefaults[.hasDismissedBlazeSectionOnMyStore] = ["\(sampleSiteID)": true]

        // When
        userDefaults.restoreBlazeSectionOnMyStore(for: sampleSiteID)

        // Then
        XCTAssertEqual(userDefaults[.hasDismissedBlazeSectionOnMyStore], ["\(sampleSiteID)": false])
    }

    func test_setDismissedBlazeSectionOnMyStore_sets_the_blaze_section_to_be_dismissed() throws {
        // Given
        let uuid = UUID().uuidString
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: uuid))
        userDefaults[.hasDismissedBlazeSectionOnMyStore] = ["\(sampleSiteID)": false]

        // When
        userDefaults.setDismissedBlazeSectionOnMyStore(for: sampleSiteID)

        // Then
        XCTAssertEqual(userDefaults[.hasDismissedBlazeSectionOnMyStore], ["\(sampleSiteID)": true])
    }
}
