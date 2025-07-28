import XCTest
@testable import Experiments

final class CachedABTestVariationProviderTests: XCTestCase {
    func test_variation_is_control_when_the_value_does_not_exist() throws {
        // Given
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))

        // When
        let cache = VariationCache(userDefaults: userDefaults)
        let provider = CachedABTestVariationProvider(cache: cache)

        // Then
        XCTAssertEqual(provider.variation(for: .mockLoggedOut), .control)
    }

    func test_correct_variation_is_returned_after_caching_it() throws {
        // Given
        let userDefaults = try XCTUnwrap(UserDefaults(suiteName: UUID().uuidString))
        let cache = VariationCache(userDefaults: userDefaults)
        let provider = CachedABTestVariationProvider(cache: cache)

        // When
        try cache.assign(variation: .treatment, for: .mockLoggedOut)

        // Then
        XCTAssertEqual(provider.variation(for: .mockLoggedOut), .treatment)
    }
}
