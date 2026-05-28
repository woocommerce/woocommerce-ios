import Foundation
import Testing
import struct Networking.POSStaffMember
@testable import PointOfSale

@Suite(.timeLimit(.minutes(5)))
struct POSStaffCacheTests {
    @Test func test_load_when_empty_then_returns_nil() {
        // Given
        let sut = POSStaffCache(storage: InMemoryKeyValueStorage())

        // When
        let result = sut.load(siteID: 1)

        // Then
        #expect(result == nil)
    }

    @Test func test_save_then_load_when_same_site_then_round_trips() {
        // Given
        let staff = [makeMember(id: 42)]
        let sut = POSStaffCache(storage: InMemoryKeyValueStorage())

        // When
        sut.save(staff, siteID: 1)

        // Then
        #expect(sut.load(siteID: 1) == staff)
    }

    @Test func test_load_when_different_site_then_returns_nil() {
        // Given
        let sut = POSStaffCache(storage: InMemoryKeyValueStorage())
        sut.save([makeMember(id: 42)], siteID: 1)

        // When / Then
        #expect(sut.load(siteID: 2) == nil)
    }

    @Test func test_clear_then_load_returns_nil() {
        // Given
        let sut = POSStaffCache(storage: InMemoryKeyValueStorage())
        sut.save([makeMember(id: 42)], siteID: 1)

        // When
        sut.clear(siteID: 1)

        // Then
        #expect(sut.load(siteID: 1) == nil)
    }

    @Test func test_hasAnyPINs_when_one_member_has_pin_then_true() {
        // Given
        let sut = POSStaffCache(storage: InMemoryKeyValueStorage())
        sut.save([makeMember(id: 1, hasPIN: true), makeMember(id: 2, hasPIN: false)], siteID: 1)

        // When / Then
        #expect(sut.hasAnyPINs(siteID: 1) == true)
    }

    @Test func test_hasAnyPINs_when_no_member_has_pin_then_false() {
        // Given
        let sut = POSStaffCache(storage: InMemoryKeyValueStorage())
        sut.save([makeMember(id: 1, hasPIN: false)], siteID: 1)

        // When / Then
        #expect(sut.hasAnyPINs(siteID: 1) == false)
    }

    @Test func test_lastFetched_records_save_time() {
        // Given
        let now = Date()
        let sut = POSStaffCache(storage: InMemoryKeyValueStorage(), now: { now })

        // When
        sut.save([makeMember(id: 1)], siteID: 1)

        // Then
        #expect(sut.lastFetched(siteID: 1) == now)
    }

    @Test func test_lastFetched_when_staff_payload_missing_then_returns_nil_even_with_valid_timestamp() {
        // Given - simulate a torn cache: timestamp written but staff key missing
        // (selective Keychain wipe / partial write). Without atomicity the session
        // would unlock POS as "no PINs" because hasAnyPINs returns false.
        let storage = InMemoryKeyValueStorage()
        let now = Date()
        let sut = POSStaffCache(storage: storage, now: { now })
        sut.save([makeMember(id: 1)], siteID: 1)
        storage.setString(nil, forKey: "staff.1")

        // When / Then
        #expect(sut.lastFetched(siteID: 1) == nil)
    }

    @Test func test_lastFetched_when_staff_payload_corrupt_then_returns_nil_even_with_valid_timestamp() {
        // Given - timestamp valid, staff payload is unreadable garbage
        let storage = InMemoryKeyValueStorage()
        let now = Date()
        let sut = POSStaffCache(storage: storage, now: { now })
        sut.save([makeMember(id: 1)], siteID: 1)
        storage.setString("not-valid-json", forKey: "staff.1")

        // When / Then
        #expect(sut.lastFetched(siteID: 1) == nil)
    }

    // MARK: - Helpers

    private func makeMember(id: Int64, hasPIN: Bool = true) -> POSStaffMember {
        let pin: POSStaffMember.PINDetails? = hasPIN
            ? .init(algo: "pbkdf2-sha256", iterations: 10000, salt: "c2FsdA==", hash: "aGFzaA==")
            : nil
        return POSStaffMember(userID: id, userLogin: "u\(id)", displayName: "U\(id)",
                              role: "pos_cashier", capabilities: ["view_pos": true], pin: pin)
    }
}
