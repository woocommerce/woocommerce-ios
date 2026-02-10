import Foundation
import Testing
@testable import Experiments

struct `Variation Cache Tests` {
    @Test func `variation is nil when the value does not exist`() throws {
        // Given
        let userDefaults = try #require(UserDefaults(suiteName: UUID().uuidString))

        // When
        let cache = VariationCache(userDefaults: userDefaults)

        // Then
        #expect(cache.variation(for: .mockLoggedOut) == nil)
    }

    @Test func `correct variation is returned after setting it`() throws {
        // Given
        let userDefaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let cache = VariationCache(userDefaults: userDefaults)

        // When
        try cache.assign(variation: .treatment, for: .mockLoggedOut)

        // Then
        #expect(cache.variation(for: .mockLoggedOut) == .treatment)
    }

    @Test func `it throws when trying to cache logged in experiment`() throws {
        // Given
        let userDefaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let cache = VariationCache(userDefaults: userDefaults)

        // When
        #expect(throws: (any Error).self) { try cache.assign(variation: .treatment, for: .mockLoggedIn) }
    }
}
