import Foundation
import Testing
import struct Yosemite.POSStaffMember
import enum Yosemite.POSStaffPreset
@testable import PointOfSale

@Suite(.timeLimit(.minutes(5)))
struct DefaultPOSPINAuthenticatorTests {
    private let siteID: Int64 = 123

    // MARK: - authenticate

    @MainActor
    @Test func test_authenticate_when_pin_matches_a_cached_member_then_returns_that_staff() async throws {
        // Given a cached member whose PIN hash matches "1234"
        let member = makeMember(userID: 7, displayName: "Manny", preset: .manager,
                                capabilities: ["woocommerce_pos_issue_refunds": true],
                                pin: pinDetails(forPIN: "1234"))
        let sut = makeSUT(cached: [member])

        // When
        let staff = try await sut.authenticate(withPIN: "1234")

        // Then
        #expect(staff.userID == 7)
        #expect(staff.displayName == "Manny")
        #expect(staff.preset == .manager)
    }

    @MainActor
    @Test func test_authenticate_when_pin_is_wrong_then_throws_invalidPIN() async throws {
        // Given a member with a different PIN
        let member = makeMember(userID: 1, pin: pinDetails(forPIN: "0000"))
        let sut = makeSUT(cached: [member])

        // When / Then — no fetcher, so a miss is simply invalid (the session decides whether to refresh+retry)
        await #expect(throws: POSAuthError.invalidPIN) {
            _ = try await sut.authenticate(withPIN: "1234")
        }
    }

    @MainActor
    @Test func test_authenticate_skips_members_without_a_pin() async throws {
        // Given one member with no PIN and one with the matching PIN
        let noPIN = makeMember(userID: 1, pin: nil)
        let matching = makeMember(userID: 2, pin: pinDetails(forPIN: "1234"))
        let sut = makeSUT(cached: [noPIN, matching])

        // When
        let staff = try await sut.authenticate(withPIN: "1234")

        // Then
        #expect(staff.userID == 2)
    }

    @MainActor
    @Test func test_authenticate_rejects_members_with_an_unsupported_algorithm() async throws {
        // Given a member whose PIN hash would match "1234" but is tagged with an unsupported algo
        let valid = pinDetails(forPIN: "1234")
        let details = POSStaffMember.PINDetails(algorithm: "bcrypt", iterations: valid.iterations,
                                                salt: valid.salt, hash: valid.hash)
        let member = makeMember(userID: 1, pin: details)
        let sut = makeSUT(cached: [member])

        // When / Then
        await #expect(throws: POSAuthError.invalidPIN) {
            _ = try await sut.authenticate(withPIN: "1234")
        }
    }

    @MainActor
    @Test func test_authenticate_rejects_members_whose_hash_exceeds_the_maximum_length() async throws {
        // Given an independently generated 65-byte PBKDF2-SHA256 hash for PIN "1234".
        // It would authenticate if the 64-byte safety limit were removed.
        let oversizedHash = "AsXBWrCDP2vAJcMBR8FNk62YU2oTmP92K5x0dxDejmPThNcfPXgK341+LETyo0QGDDSAQdFMgItGZ/5ecGXxONk="
        let details = POSStaffMember.PINDetails(algorithm: "pbkdf2-sha256", iterations: 1_000,
                                                salt: "c2FsdC1mb3ItdGVzdHM=", hash: oversizedHash)
        let member = makeMember(userID: 1, pin: details)
        let sut = makeSUT(cached: [member])

        // When / Then — the oversized hash is treated as invalid data rather than fed to PBKDF2
        await #expect(throws: POSAuthError.invalidPIN) {
            _ = try await sut.authenticate(withPIN: "1234")
        }
    }

    @MainActor
    @Test func test_authenticate_keeps_only_known_pos_capabilities_that_are_granted() async throws {
        // Given a member with a granted known cap, a denied known cap, and an unknown cap
        let member = makeMember(userID: 1,
                                capabilities: [
                                    "woocommerce_pos_issue_refunds": true,
                                    "woocommerce_pos_create_coupons": false,
                                    "some_unknown_cap": true
                                ],
                                pin: pinDetails(forPIN: "1234"))
        let sut = makeSUT(cached: [member])

        // When
        let staff = try await sut.authenticate(withPIN: "1234")

        // Then only the granted, recognized capability survives
        #expect(staff.capabilities == ["woocommerce_pos_issue_refunds"])
        #expect(staff.hasCapability(.issueRefunds))
        #expect(!staff.hasCapability(.createCoupons))
    }

    @MainActor
    @Test func test_authenticate_when_member_has_a_valid_pin_but_no_recognized_pos_capabilities_then_returns_staff_with_none() async throws {
        // Given a member with a matching PIN but only capabilities the client doesn't recognize
        let member = makeMember(userID: 3,
                                capabilities: ["some_legacy_cap": true, "another_unknown_cap": true],
                                pin: pinDetails(forPIN: "1234"))
        let sut = makeSUT(cached: [member])

        // When
        let staff = try await sut.authenticate(withPIN: "1234")

        // Then sign-in still succeeds (the PIN is valid) but the staff carries no POS capabilities
        #expect(staff.userID == 3)
        #expect(staff.capabilities.isEmpty)
    }

    // MARK: - verify(managerPIN:)

    @MainActor
    @Test func test_verify_when_manager_holds_the_capability_then_does_not_throw() async throws {
        let manager = makeMember(userID: 5, displayName: "Morgan", preset: .manager,
                                 capabilities: ["woocommerce_pos_issue_refunds": true],
                                 pin: pinDetails(forPIN: "9999"))
        let sut = makeSUT(cached: [manager])

        // When / Then — succeeds without throwing
        try await sut.verify(managerPIN: "9999", authorizes: .issueRefunds)
    }

    @MainActor
    @Test func test_verify_when_manager_lacks_the_capability_then_throws_invalidPIN() async throws {
        let cashier = makeMember(userID: 6, capabilities: [:],
                                 pin: pinDetails(forPIN: "9999"))
        let sut = makeSUT(cached: [cashier])

        await #expect(throws: POSAuthError.invalidPIN) {
            try await sut.verify(managerPIN: "9999", authorizes: .issueRefunds)
        }
    }
}

// MARK: - Helpers

private extension DefaultPOSPINAuthenticatorTests {
    @MainActor
    func makeSUT(cached: [POSStaffMember] = []) -> DefaultPOSPINAuthenticator {
        let cache = POSStaffCache(storage: InMemoryStaffStorage())
        cache.save(cached, siteID: siteID)
        return DefaultPOSPINAuthenticator(cache: cache, siteID: siteID)
    }

    func makeMember(userID: Int64,
                    displayName: String = "User",
                    preset: POSStaffPreset = .cashier,
                    capabilities: [String: Bool] = ["woocommerce_pos_issue_refunds": true],
                    pin: POSStaffMember.PINDetails?) -> POSStaffMember {
        POSStaffMember(userID: userID, displayName: displayName, preset: preset,
                       capabilities: capabilities, pin: pin)
    }

    /// Fixed vectors generated independently with Python hashlib.pbkdf2_hmac("sha256", ..., 1000, 32),
    /// salt b"salt-for-tests". Do not derive fixtures with the authenticator's CommonCrypto implementation.
    func pinDetails(forPIN pin: String) -> POSStaffMember.PINDetails {
        let hashes = [
            "1234": "AsXBWrCDP2vAJcMBR8FNk62YU2oTmP92K5x0dxDejmM=",
            "0000": "O9i8z9tei0Mk3Z8njczJOabhcNtQo1wpUx64SrrtMII=",
            "9999": "hr3SQ7Kf8r9X1SHVCJ5WWRGQxGNmM5t4QJw51VqrlXg="
        ]
        guard let hash = hashes[pin] else {
            // Only the fixed PINs above are valid test fixtures; an unknown PIN is a test setup error.
            preconditionFailure("Add an independent PIN hash vector for this fixture")
        }
        return POSStaffMember.PINDetails(algorithm: "pbkdf2-sha256",
                                         iterations: 1_000,
                                         salt: "c2FsdC1mb3ItdGVzdHM=",
                                         hash: hash)
    }
}
