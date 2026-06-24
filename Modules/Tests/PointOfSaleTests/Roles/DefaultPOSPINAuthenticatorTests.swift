import CommonCrypto
import Foundation
import Testing
import struct Yosemite.POSStaffMember
import enum Yosemite.POSStaffPreset
@testable import PointOfSale

struct DefaultPOSPINAuthenticatorTests {
    private let siteID: Int64 = 123

    // MARK: - authenticate

    @MainActor
    @Test func test_authenticate_when_pin_matches_a_cached_member_then_returns_that_staff() async throws {
        // Given a cached member whose PIN hash matches "1234"
        let member = makeMember(userID: 7, displayName: "Manny", preset: .manager,
                                capabilities: ["woocommerce_pos_process_sales": true, "woocommerce_pos_issue_refunds": true],
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
        // Given a cached member whose PIN hash is far larger than a real PBKDF2-SHA256 digest,
        // simulating a corrupted or tampered cache entry
        let oversizedHash = Data(repeating: 0, count: 1_024).base64EncodedString()
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
                                    "woocommerce_pos_process_sales": true,
                                    "woocommerce_pos_issue_refunds": false,
                                    "some_unknown_cap": true
                                ],
                                pin: pinDetails(forPIN: "1234"))
        let sut = makeSUT(cached: [member])

        // When
        let staff = try await sut.authenticate(withPIN: "1234")

        // Then only the granted, recognized capability survives
        #expect(staff.capabilities == ["woocommerce_pos_process_sales"])
        #expect(staff.hasCapability(.processSales))
        #expect(!staff.hasCapability(.issueRefunds))
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

        // When
        let staff = try await sut.verify(managerPIN: "9999", authorizes: .issueRefunds)

        // Then
        #expect(staff.userID == 5)
    }

    @MainActor
    @Test func test_verify_when_manager_lacks_the_capability_then_throws_invalidPIN() async throws {
        let cashier = makeMember(userID: 6, capabilities: ["woocommerce_pos_process_sales": true],
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
                    capabilities: [String: Bool] = ["woocommerce_pos_process_sales": true],
                    pin: POSStaffMember.PINDetails?) -> POSStaffMember {
        POSStaffMember(userID: userID, displayName: displayName, preset: preset,
                       capabilities: capabilities, pin: pin)
    }

    /// Builds `PINDetails` whose hash is a genuine PBKDF2-HMAC-SHA256 derivation of `pin`, so the
    /// authenticator's real verification path is exercised end to end.
    func pinDetails(forPIN pin: String,
                    saltBase64: String = "c2FsdC1mb3ItdGVzdHM=",
                    iterations: Int = 1_000) -> POSStaffMember.PINDetails {
        let salt = Data(base64Encoded: saltBase64)!
        let pinData = pin.data(using: .utf8)!
        var derived = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        let status = salt.withUnsafeBytes { saltBytes -> Int32 in
            pinData.withUnsafeBytes { pinBytes -> Int32 in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    pinBytes.baseAddress?.assumingMemoryBound(to: Int8.self),
                    pinData.count,
                    saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    UInt32(iterations),
                    &derived,
                    derived.count
                )
            }
        }
        // Fail fast if key derivation fails — otherwise the helper would hand back an all-zero hash
        // and the test would silently assert against meaningless data.
        precondition(status == kCCSuccess, "PBKDF2 derivation failed in test helper (status: \(status))")
        return POSStaffMember.PINDetails(algorithm: "pbkdf2-sha256",
                                         iterations: iterations,
                                         salt: saltBase64,
                                         hash: Data(derived).base64EncodedString())
    }
}
