import Foundation
import Testing
import struct Networking.POSStaffMember
@testable import PointOfSale

@Suite(.timeLimit(.minutes(5)))
struct DefaultPOSPINAuthenticatorTests {
    private let knownPIN = "1234"
    private let knownSalt = "c2FsdHkxMjM0"
    // PBKDF2-HMAC-SHA-256(pin="1234", salt=base64Decode("c2FsdHkxMjM0"), iterations=10000, dklen=32)
    // -> base64 of the 32-byte derived key. Computed once via python hashlib; reused across tests.
    private let knownHash = "XYi15Cgtdy5Uq8RAJQtdpV39sZR7/Q1kj3ZDXar1UQg="

    @Test func test_authenticate_when_pin_matches_cached_hash_then_returns_staff() async throws {
        // Given
        let member = makeMember(id: 42, hasPIN: true, salt: knownSalt, hash: knownHash)
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        cache.save([member], siteID: 1)
        let sut = makeSUT(cache: cache, fetcher: MockPOSStaffFetcher(staff: [member]), siteID: 1)

        // When
        let staff = try await sut.authenticate(withPIN: knownPIN)

        // Then
        #expect(staff.userID == 42)
        #expect(staff.userLogin == "u42")
    }

    @Test func test_authenticate_when_pin_does_not_match_after_refetch_then_throws_invalidPIN() async {
        // Given
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        cache.save([makeMember(id: 99, hasPIN: true, salt: "diff", hash: "diff")], siteID: 1)
        let sut = makeSUT(cache: cache,
                         fetcher: MockPOSStaffFetcher(staff: [makeMember(id: 99, hasPIN: true, salt: "diff", hash: "diff")]),
                         siteID: 1)

        // When / Then
        await #expect(throws: POSAuthError.invalidPIN) {
            _ = try await sut.authenticate(withPIN: "9999")
        }
    }

    @Test func test_authenticate_when_first_lookup_misses_then_refetches_once_and_matches() async throws {
        // Given - cache initially has no matching staff
        let oldMember = makeMember(id: 99, hasPIN: true, salt: "diff", hash: "diff")
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        cache.save([oldMember], siteID: 1)

        // Refetch returns updated staff containing the real match
        let newMember = makeMember(id: 42, hasPIN: true, salt: knownSalt, hash: knownHash)
        let fetcher = MockPOSStaffFetcher(staff: [newMember])
        let sut = makeSUT(cache: cache, fetcher: fetcher, siteID: 1)

        // When
        let staff = try await sut.authenticate(withPIN: knownPIN)

        // Then
        #expect(staff.userID == 42)
        #expect(fetcher.calls == 1)
        #expect(cache.load(siteID: 1)?.first?.userID == 42)
    }

    @Test func test_authenticate_when_member_pin_is_nil_then_skipped() async {
        // Given
        let member = makeMember(id: 42, hasPIN: false)
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        cache.save([member], siteID: 1)
        let sut = makeSUT(cache: cache, fetcher: MockPOSStaffFetcher(staff: [member]), siteID: 1)

        // When / Then
        await #expect(throws: POSAuthError.invalidPIN) {
            _ = try await sut.authenticate(withPIN: knownPIN)
        }
    }

    @Test func test_authenticate_when_algo_is_unknown_then_skipped() async {
        // Given
        let member = POSStaffMember(
            userID: 42, userLogin: "u42", displayName: "U42", role: "pos_cashier",
            capabilities: ["view_pos": true],
            pin: .init(algo: "argon2id", iterations: 10000, salt: knownSalt, hash: knownHash)
        )
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        cache.save([member], siteID: 1)
        let sut = makeSUT(cache: cache, fetcher: MockPOSStaffFetcher(staff: [member]), siteID: 1)

        // When / Then
        await #expect(throws: POSAuthError.invalidPIN) {
            _ = try await sut.authenticate(withPIN: knownPIN)
        }
    }

    @Test func test_authenticate_filters_capabilities_to_pos_caps_only() async throws {
        // Given - server returns many caps; only POSCapability raw values land in POSStaff.capabilities
        let member = POSStaffMember(
            userID: 42, userLogin: "u42", displayName: "U42", role: "pos_cashier",
            capabilities: [
                "view_pos": true,
                "refund_shop_orders": true,
                "manage_woocommerce": true,
                "read": true
            ],
            pin: .init(algo: "pbkdf2-sha256", iterations: 10000, salt: knownSalt, hash: knownHash)
        )
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        cache.save([member], siteID: 1)
        let sut = makeSUT(cache: cache, fetcher: MockPOSStaffFetcher(staff: [member]), siteID: 1)

        // When
        let staff = try await sut.authenticate(withPIN: knownPIN)

        // Then
        #expect(staff.capabilities == ["view_pos", "refund_shop_orders"])
    }

    @Test func test_verify_when_pin_matches_cap_holder_then_returns_approver() async throws {
        // Given - manager has refund cap
        let manager = makeMember(id: 7, hasPIN: true, salt: knownSalt, hash: knownHash,
                                capabilities: ["view_pos": true, "refund_shop_orders": true])
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        cache.save([manager], siteID: 1)
        let sut = makeSUT(cache: cache, fetcher: MockPOSStaffFetcher(staff: [manager]), siteID: 1)

        // When
        let approver = try await sut.verify(managerPIN: knownPIN, authorizes: .refundShopOrders)

        // Then
        #expect(approver.userID == 7)
    }

    @Test func test_verify_when_pin_matches_but_no_cap_then_throws_invalidPIN() async {
        // Given - cashier matched but lacks the cap
        let cashier = makeMember(id: 42, hasPIN: true, salt: knownSalt, hash: knownHash,
                                 capabilities: ["view_pos": true])
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        cache.save([cashier], siteID: 1)
        let sut = makeSUT(cache: cache, fetcher: MockPOSStaffFetcher(staff: [cashier]), siteID: 1)

        // When / Then
        await #expect(throws: POSAuthError.invalidPIN) {
            _ = try await sut.verify(managerPIN: knownPIN, authorizes: .refundShopOrders)
        }
    }

    @Test func test_hasAnyPINs_passes_through_to_cache() async throws {
        // Given
        let cache = POSStaffCache(storage: InMemoryKeyValueStorage())
        cache.save([makeMember(id: 1, hasPIN: true)], siteID: 1)
        let sut = makeSUT(cache: cache, fetcher: MockPOSStaffFetcher(staff: []), siteID: 1)

        // When
        let result = try await sut.hasAnyPINs()

        // Then
        #expect(result == true)
    }

    // MARK: - Helpers

    private func makeSUT(cache: POSStaffCache, fetcher: POSStaffFetching, siteID: Int64) -> DefaultPOSPINAuthenticator {
        DefaultPOSPINAuthenticator(cache: cache, fetcher: fetcher, siteID: siteID)
    }

    private func makeMember(id: Int64,
                           hasPIN: Bool,
                           salt: String = "c2FsdA==",
                           hash: String = "aGFzaA==",
                           capabilities: [String: Bool] = ["view_pos": true]) -> POSStaffMember {
        let pin: POSStaffMember.PINDetails? = hasPIN
            ? .init(algo: "pbkdf2-sha256", iterations: 10000, salt: salt, hash: hash)
            : nil
        return POSStaffMember(userID: id, userLogin: "u\(id)", displayName: "U\(id)",
                              role: "pos_cashier", capabilities: capabilities, pin: pin)
    }
}
