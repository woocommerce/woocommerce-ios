import Foundation
import Testing
@testable import PointOfSale

struct POSOnboardingGuidePreferencesTests {
    @Test func test_hasCompletedGuide_when_nothing_is_saved_then_returns_false() throws {
        // Given
        let scope = try PreferencesScope()
        let sut = POSOnboardingGuidePreferences(userDefaults: scope.defaults)

        // When, Then
        #expect(sut.hasCompletedGuide(for: 123) == false)
    }

    @Test func test_markGuideCompleted_when_saved_then_survives_new_preferences_instance() throws {
        // Given
        let scope = try PreferencesScope()
        let sut = POSOnboardingGuidePreferences(userDefaults: scope.defaults)

        // When
        sut.markGuideCompleted(for: 123)
        let reloaded = POSOnboardingGuidePreferences(userDefaults: scope.defaults)

        // Then
        #expect(reloaded.hasCompletedGuide(for: 123))
    }

    @Test func test_markGuideCompleted_when_completed_for_one_store_then_other_stores_are_not_completed() throws {
        // Given
        let scope = try PreferencesScope()
        let sut = POSOnboardingGuidePreferences(userDefaults: scope.defaults)

        // When
        sut.markGuideCompleted(for: 123)

        // Then
        #expect(sut.hasCompletedGuide(for: 123))
        #expect(sut.hasCompletedGuide(for: 456) == false)
    }

    @Test func test_clearAll_when_logging_out_then_removes_all_store_completions_and_preserves_other_preferences() throws {
        // Given
        let scope = try PreferencesScope()
        let sut = POSOnboardingGuidePreferences(userDefaults: scope.defaults)
        sut.markGuideCompleted(for: 123)
        sut.markGuideCompleted(for: 456)
        scope.defaults.set("keep", forKey: "unrelated.preference")

        // When
        POSOnboardingGuidePersistence.clearAll(userDefaults: scope.defaults)

        // Then
        #expect(scope.defaults.object(forKey: POSOnboardingGuidePersistence.key(for: 123)) == nil)
        #expect(scope.defaults.object(forKey: POSOnboardingGuidePersistence.key(for: 456)) == nil)
        #expect(sut.hasCompletedGuide(for: 123) == false)
        #expect(scope.defaults.string(forKey: "unrelated.preference") == "keep")
    }
}

private final class PreferencesScope {
    let defaults: UserDefaults
    private let suiteName = "POSOnboardingGuidePreferencesTests.\(UUID().uuidString)"

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
