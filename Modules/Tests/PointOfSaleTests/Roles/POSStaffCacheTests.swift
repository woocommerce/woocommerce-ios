import Foundation
import Testing
import struct Yosemite.POSStaffMember
@testable import PointOfSale

struct POSStaffCacheTests {

    // MARK: - load / save round-trip

    @Test func test_load_when_nothing_saved_then_returns_nil() {
        // Given
        let (cache, _) = makeCache()

        // When
        let loaded = cache.load(siteID: 1)

        // Then
        #expect(loaded == nil)
    }

    @Test func test_save_then_load_when_same_site_then_returns_full_member_list() {
        // Given
        let (cache, _) = makeCache()
        let members = [makeMember(userID: 1, pin: makePIN()), makeMember(userID: 2, pin: nil)]

        // When
        cache.save(members, siteID: 99)

        // Then
        #expect(cache.load(siteID: 99) == members)
    }

    @Test func test_save_when_different_sites_share_a_user_id_then_each_site_keeps_its_own_record() {
        // Given
        // Same userID on both sites but different records — proves lookups are keyed per-site,
        // not deduplicated by userID.
        let (cache, _) = makeCache()
        let siteAMembers = [makeMember(userID: 1, displayName: "Alice")]
        let siteBMembers = [makeMember(userID: 1, displayName: "Bob")]

        // When
        cache.save(siteAMembers, siteID: 10)
        cache.save(siteBMembers, siteID: 20)

        // Then
        #expect(cache.load(siteID: 10) == siteAMembers)
        #expect(cache.load(siteID: 20) == siteBMembers)
    }

    // MARK: - clear

    @Test func test_clear_when_site_has_cache_then_load_and_lastFetched_return_nil() {
        // Given
        let (cache, _) = makeCache()
        cache.save([makeMember(userID: 1)], siteID: 1)

        // When
        cache.clear(siteID: 1)

        // Then
        #expect(cache.load(siteID: 1) == nil)
        #expect(cache.lastFetched(siteID: 1) == nil)
    }

    @Test func test_clear_when_other_site_cached_then_only_target_site_cleared() {
        // Given
        let (cache, _) = makeCache()
        cache.save([makeMember(userID: 1)], siteID: 1)
        cache.save([makeMember(userID: 2)], siteID: 2)

        // When
        cache.clear(siteID: 1)

        // Then
        #expect(cache.load(siteID: 1) == nil)
        #expect(cache.load(siteID: 2) == [makeMember(userID: 2)])
    }

    // MARK: - hasAnyPINs

    @Test func test_hasAnyPINs_when_no_cache_then_false() {
        // Given
        let (cache, _) = makeCache()

        // Then
        #expect(cache.hasAnyPINs(siteID: 1) == false)
    }

    @Test func test_hasAnyPINs_when_no_member_has_pin_then_false() {
        // Given
        let (cache, _) = makeCache()
        cache.save([makeMember(userID: 1, pin: nil), makeMember(userID: 2, pin: nil)], siteID: 1)

        // Then
        #expect(cache.hasAnyPINs(siteID: 1) == false)
    }

    @Test func test_hasAnyPINs_when_at_least_one_member_has_pin_then_true() {
        // Given
        let (cache, _) = makeCache()
        cache.save([makeMember(userID: 1, pin: nil), makeMember(userID: 2, pin: makePIN())], siteID: 1)

        // Then
        #expect(cache.hasAnyPINs(siteID: 1) == true)
    }

    // MARK: - lastFetched

    @Test func test_lastFetched_when_nothing_saved_then_nil() {
        // Given
        let (cache, _) = makeCache()

        // Then
        #expect(cache.lastFetched(siteID: 1) == nil)
    }

    @Test func test_lastFetched_when_saved_then_round_trips_the_timestamp() {
        // Given
        // Fractional seconds exercise the round-trip through the persisted string representation.
        let fixedNow = Date(timeIntervalSince1970: 1_700_000_000.5)
        let (cache, _) = makeCache(now: { fixedNow })

        // When
        cache.save([makeMember(userID: 1)], siteID: 1)

        // Then
        #expect(cache.lastFetched(siteID: 1) == fixedNow)
    }

    @Test func test_lastFetched_when_payload_missing_but_timestamp_present_then_nil() {
        // Given
        // Reproduces a torn cache (timestamp written, payload lost). The staff key format is part of
        // the on-disk persistence contract, so reaching for it directly here is intentional.
        let (cache, storage) = makeCache()
        cache.save([makeMember(userID: 1)], siteID: 1)

        // When
        storage.setString(nil, forKey: "staff.1")

        // Then
        #expect(cache.lastFetched(siteID: 1) == nil)
    }
}

// MARK: - Helpers

private extension POSStaffCacheTests {
    func makeCache(now: @escaping @Sendable () -> Date = { Date() }) -> (POSStaffCache, InMemoryPOSStaffStorage) {
        let storage = InMemoryPOSStaffStorage()
        return (POSStaffCache(storage: storage, now: now), storage)
    }

    func makeMember(userID: Int64,
                    displayName: String? = nil,
                    pin: POSStaffMember.PINDetails? = nil) -> POSStaffMember {
        POSStaffMember(userID: userID,
                       displayName: displayName ?? "User \(userID)",
                       preset: "pos_cashier",
                       capabilities: ["pos_process_payments": true],
                       pin: pin)
    }

    func makePIN() -> POSStaffMember.PINDetails {
        POSStaffMember.PINDetails(algorithm: "pbkdf2-sha256", iterations: 5000, salt: "c2FsdA==", hash: "aGFzaA==")
    }
}

/// In-memory `POSStaffKeyValueStorage` stub. `@unchecked Sendable` is required because the protocol
/// is `Sendable` while this holds mutable state; it's sound because each test owns its own instance
/// and never shares it across tasks.
private final class InMemoryPOSStaffStorage: POSStaffKeyValueStorage, @unchecked Sendable {
    private var store: [String: String] = [:]

    func string(forKey key: String) -> String? {
        store[key]
    }

    func setString(_ value: String?, forKey key: String) {
        store[key] = value
    }

    func removeAll() {
        store.removeAll()
    }
}
