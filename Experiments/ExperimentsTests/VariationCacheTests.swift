import XCTest
@testable import Experiments

final class VariationCacheTests: XCTestCase {
    func test_variation_is_nil_when_the_value_does_not_exist() throws {
        // Given
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        // When
        let cache = VariationCache(userDefaults: userDefaults)

        // Then
        XCTAssertNil(cache.variation(for: .mockLoggedOut))
    }

    func test_correct_variation_is_returned_after_setting_it() throws {
        // Given
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let cache = VariationCache(userDefaults: userDefaults)

        // When
        try cache.assign(variation: .treatment, for: .mockLoggedOut)

        // Then
        XCTAssertEqual(cache.variation(for: .mockLoggedOut), .treatment)
    }

    func test_it_throws_when_trying_to_cache_logged_in_experiment() throws {
        // Given
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let cache = VariationCache(userDefaults: userDefaults)

        // When
        XCTAssertThrowsError(try cache.assign(variation: .treatment, for: .mockLoggedIn))
    }
}
