import Foundation
import Testing
@testable import PointOfSale

struct POSCustomAmountTaxPreferencesTests {
    @Test func test_isTaxable_when_no_choice_is_saved_then_defaults_to_false() throws {
        // Given
        let scope = try PreferencesScope()
        let sut = POSCustomAmountTaxPreferences(userDefaults: scope.defaults)

        // When, Then
        #expect(sut.isTaxable(for: 123) == false)
    }

    @Test(arguments: [true, false])
    func test_setTaxable_when_saved_then_survives_new_preferences_instance(isTaxable: Bool) throws {
        // Given
        let scope = try PreferencesScope()
        let sut = POSCustomAmountTaxPreferences(userDefaults: scope.defaults)
        sut.setTaxable(!isTaxable, for: 123)

        // When
        sut.setTaxable(isTaxable, for: 123)
        let reloaded = POSCustomAmountTaxPreferences(userDefaults: scope.defaults)

        // Then
        #expect(reloaded.isTaxable(for: 123) == isTaxable)
    }

    @Test func test_setTaxable_when_switching_stores_then_preserves_each_stores_choice() throws {
        // Given
        let scope = try PreferencesScope()
        let sut = POSCustomAmountTaxPreferences(userDefaults: scope.defaults)

        // When
        sut.setTaxable(true, for: 123)
        sut.setTaxable(false, for: 456)

        // Then
        #expect(sut.isTaxable(for: 123))
        #expect(sut.isTaxable(for: 456) == false)
        #expect(sut.isTaxable(for: 789) == false)
    }

    @Test func test_clearAll_when_logging_out_then_removes_all_store_choices_and_preserves_other_preferences() throws {
        // Given
        let scope = try PreferencesScope()
        let sut = POSCustomAmountTaxPreferences(userDefaults: scope.defaults)
        sut.setTaxable(true, for: 123)
        sut.setTaxable(false, for: 456)
        scope.defaults.set("keep", forKey: "unrelated.preference")

        // When
        POSCustomAmountTaxPersistence.clearAll(userDefaults: scope.defaults)

        // Then
        #expect(scope.defaults.object(forKey: POSCustomAmountTaxPersistence.key(for: 123)) == nil)
        #expect(scope.defaults.object(forKey: POSCustomAmountTaxPersistence.key(for: 456)) == nil)
        #expect(sut.isTaxable(for: 123) == false)
        #expect(scope.defaults.string(forKey: "unrelated.preference") == "keep")
    }
}

private final class PreferencesScope {
    let defaults: UserDefaults
    private let suiteName = "POSCustomAmountTaxPreferencesTests.\(UUID().uuidString)"

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
