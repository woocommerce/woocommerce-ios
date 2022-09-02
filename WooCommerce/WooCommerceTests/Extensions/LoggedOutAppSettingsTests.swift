import XCTest
@testable import WooCommerce

final class LoggedOutAppSettingsTests: XCTestCase {
    func test_hasFinishedOnboarding_is_false_when_the_value_does_not_exist() throws {
        // Given
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        // When
        let settings = LoggedOutAppSettings(userDefaults: userDefaults)

        // Then
        XCTAssertFalse(settings.hasFinishedOnboarding)
    }

    func test_hasFinishedOnboarding_is_true_after_setting_it() throws {
        // Given
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let settings = LoggedOutAppSettings(userDefaults: userDefaults)

        // When
        settings.setHasFinishedOnboarding(true)

        // Then
        XCTAssertTrue(settings.hasFinishedOnboarding)
    }
}
