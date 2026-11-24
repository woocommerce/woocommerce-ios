import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct POSLockSettingsTests {
    private let defaultsScope = POSLockSettingsTestDefaults()

    @Test func test_preferences_when_nothing_is_saved_then_uses_spec_defaults() {
        // Given / When
        let sut = POSLockSettings(siteID: 1, userDefaults: defaultsScope.defaults)

        // Then
        #expect(sut.preferences.locksWhenPOSOpens)
        #expect(sut.preferences.locksInBackground)
        #expect(!sut.preferences.locksAfterSale)
        #expect(sut.preferences.inactivityTimeout == .fiveMinutes)
    }

    @Test func test_update_when_settings_are_recreated_then_keeps_values_for_that_store_only() {
        // Given
        let sut = POSLockSettings(siteID: 1, userDefaults: defaultsScope.defaults)

        // When
        sut.update {
            $0.locksWhenPOSOpens = false
            $0.locksInBackground = false
            $0.locksAfterSale = true
            $0.inactivityTimeout = .fifteenMinutes
        }

        // Then
        let recreated = POSLockSettings(siteID: 1, userDefaults: defaultsScope.defaults)
        #expect(recreated.preferences == POSLockPreferences(locksWhenPOSOpens: false,
                                                            locksInBackground: false,
                                                            locksAfterSale: true,
                                                            inactivityTimeout: .fifteenMinutes))
        #expect(POSLockSettings(siteID: 2, userDefaults: defaultsScope.defaults).preferences == POSLockPreferences())
    }

    @Test func test_clearAll_when_logging_out_then_restores_defaults_for_every_store() throws {
        // Given
        POSLockSettings(siteID: 1, userDefaults: defaultsScope.defaults).update { $0.locksAfterSale = true }
        POSLockSettings(siteID: 2, userDefaults: defaultsScope.defaults).update { $0.inactivityTimeout = .never }

        // When
        try POSRolesPersistence.clearAll(pinStorage: InMemoryPOSSecureStorage(), userDefaults: defaultsScope.defaults)

        // Then
        #expect(POSLockSettings(siteID: 1, userDefaults: defaultsScope.defaults).preferences == POSLockPreferences())
        #expect(POSLockSettings(siteID: 2, userDefaults: defaultsScope.defaults).preferences == POSLockPreferences())
    }

    @Test func test_preferences_when_saved_data_is_unreadable_then_uses_defaults() {
        // Given
        defaultsScope.defaults.set(Data("invalid".utf8), forKey: "com.woocommerce.pos.lockSettings.1")

        // When
        let sut = POSLockSettings(siteID: 1, userDefaults: defaultsScope.defaults)

        // Then
        #expect(sut.preferences == POSLockPreferences())
    }

    @Test(arguments: POSInactivityLockTimeout.allCases)
    func test_interval_when_timeout_is_selected_then_matches_minutes_or_never(timeout: POSInactivityLockTimeout) {
        // Given / When
        let interval = timeout.interval

        // Then
        #expect(interval == (timeout == .never ? nil : TimeInterval(timeout.rawValue) * 60))
    }
}

private final class POSLockSettingsTestDefaults {
    let defaults: UserDefaults
    private let name = "POSLockSettingsTests.\(UUID().uuidString)"
    init() { defaults = UserDefaults(suiteName: name) ?? .standard }
    deinit { defaults.removePersistentDomain(forName: name) }
}
