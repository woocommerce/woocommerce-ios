import Foundation
import Testing
@testable import WordPressAuthenticator

/// Tests for `MagicLinkSiteAddressStorage`: save/read-once persistence of the login store address.
struct MagicLinkSiteAddressStorageTests {

    /// A fresh, isolated `UserDefaults` so tests don't pollute each other.
    private func makeEphemeralDefaults() -> UserDefaults {
        let suiteName = "MagicLinkSiteAddressStorageTests.\(UUID().uuidString)"
        // Force-unwrap is safe: `suiteName` is never nil/empty nor the bundle id, the only cases that return nil.
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func test_consume_when_address_saved_then_returns_saved_address() {
        // Given a persisted store address
        let storage = MagicLinkSiteAddressStorage(userDefaults: makeEphemeralDefaults())
        storage.save("https://yourwoosite.com")

        // When consuming it
        let consumed = storage.consume()

        // Then the round trip returns the entered address so the epilogue can match the store
        #expect(consumed == "https://yourwoosite.com")
    }

    @Test func test_consume_when_called_twice_then_second_call_returns_nil() {
        // Given a persisted store address
        let storage = MagicLinkSiteAddressStorage(userDefaults: makeEphemeralDefaults())
        storage.save("https://yourwoosite.com")

        // When consuming it once
        _ = storage.consume()

        // Then it is read-once: a second consume finds nothing (prevents a later login reusing it)
        #expect(storage.consume() == nil)
    }

    @Test func test_save_when_value_is_nil_then_clears_previous_value() {
        // Given a persisted store address
        let storage = MagicLinkSiteAddressStorage(userDefaults: makeEphemeralDefaults())
        storage.save("https://yourwoosite.com")

        // When a later request saves nil (latest request wins)
        storage.save(nil)

        // Then the previous value is cleared
        #expect(storage.consume() == nil)
    }

    @Test func test_consume_when_entry_older_than_ttl_then_returns_nil() {
        // Given an address saved 16 minutes ago (TTL is 15)
        let defaults = makeEphemeralDefaults()
        let savedAt = Date()
        MagicLinkSiteAddressStorage(userDefaults: defaults, now: { savedAt }).save("https://yourwoosite.com")

        // When consuming after the magic link would have expired
        let consumer = MagicLinkSiteAddressStorage(userDefaults: defaults, now: { savedAt.addingTimeInterval(16 * 60) })
        let consumed = consumer.consume()

        // Then the stale address is not restored into an unrelated later login
        #expect(consumed == nil)
    }

    @Test func test_save_when_value_is_empty_then_clears_previous_value() {
        // Given a persisted store address
        let storage = MagicLinkSiteAddressStorage(userDefaults: makeEphemeralDefaults())
        storage.save("https://yourwoosite.com")

        // When a later generic-entry request saves an empty string
        storage.save("")

        // Then the previous value is cleared so it can't leak into the generic flow
        #expect(storage.consume() == nil)
    }
}
